# JikJoken API Specification

**Version:** 0.1.0
**Julia Port of:** [TikToken](https://github.com/openai/tiktoken) by OpenAI

## Overview

JikJoken is a Julia port of TikToken, providing fast BPE (Byte Pair Encoding) tokenization for use with OpenAI's language models. The API closely mirrors TikToken's Python interface while following Julia conventions.

## Design Principles

1. **API Compatibility**: Mirror TikToken's Python API as closely as possible
2. **Julia Conventions**: Use Julia idioms (multiple dispatch, keyword arguments, types)
3. **Performance**: Leverage Rust core via C FFI with minimal overhead
4. **Type Safety**: Use Julia's type system for better ergonomics
5. **Zero-Copy**: Minimize allocations in the Julia-Rust boundary

## Installation

```julia
using Pkg
Pkg.add("JikJoken")
```

## Core Types

### `Encoding`

The main type representing a tokenization scheme.

```julia
struct Encoding
    name::String
    # Internal: Opaque pointer to Rust encoding object
    _handle::Ptr{Cvoid}
    # Cached properties
    _max_token_value::Int
    _eot_token::Union{Int, Nothing}
    _special_tokens::Set{String}
    _n_vocab::Int
end
```

### Special Token Control

```julia
# Type aliases for clarity
const AllowedSpecial = Union{Symbol, Set{String}}  # :all or Set{"<|endoftext|>", ...}
const DisallowedSpecial = Union{Symbol, Set{String}}  # :all or Set{...}
```

## Top-Level Functions

### `get_encoding(name::String) -> Encoding`

Get an encoding by name.

**Parameters:**
- `name::String`: Encoding name (e.g., "o200k_base", "cl100k_base", "gpt2")

**Returns:**
- `Encoding`: The requested encoding

**Example:**
```julia
using JikJoken

enc = get_encoding("o200k_base")
```

**Available encodings:**
- `"o200k_base"` - Current standard encoding
- `"cl100k_base"` - Legacy encoding for GPT-3.5/4
- `"p50k_base"` - GPT-3 base
- `"r50k_base"` - GPT-2 base
- `"gpt2"` - Original GPT-2

### `encoding_for_model(model_name::String) -> Encoding`

Get the appropriate encoding for a specific OpenAI model.

**Parameters:**
- `model_name::String`: Model name (e.g., "gpt-4o", "gpt-4", "gpt-3.5-turbo")

**Returns:**
- `Encoding`: The encoding used by that model

**Example:**
```julia
enc = encoding_for_model("gpt-4o")
```

### `list_encoding_names() -> Vector{String}`

List all available encoding names.

**Returns:**
- `Vector{String}`: Array of encoding names

**Example:**
```julia
names = list_encoding_names()
# ["o200k_base", "cl100k_base", "p50k_base", "r50k_base", "gpt2"]
```

### `encoding_name_for_model(model_name::String) -> String`

Get the encoding name for a model without loading the encoding.

**Parameters:**
- `model_name::String`: Model name

**Returns:**
- `String`: Encoding name

**Example:**
```julia
name = encoding_name_for_model("gpt-4o")  # "o200k_base"
```

## Encoding Methods

### Core Encoding Methods

#### `encode(enc::Encoding, text::String; allowed_special::AllowedSpecial=Set{String}(), disallowed_special::DisallowedSpecial=:all) -> Vector{Int}`

Encode text to tokens with special token control.

**Parameters:**
- `text::String`: Text to encode
- `allowed_special::AllowedSpecial`: Special tokens to allow
  - `:all` - Allow all special tokens
  - `Set{String}()` - (default) Allow no special tokens
  - `Set{"<|endoftext|>"}` - Allow specific tokens
- `disallowed_special::DisallowedSpecial`: Special tokens to disallow
  - `:all` - (default) Disallow all special tokens not in `allowed_special`
  - `Set{String}()` - Disallow none (no error on special tokens)
  - `Set{"<|fim_prefix|>"}` - Disallow specific tokens

**Returns:**
- `Vector{Int}`: Token IDs

**Throws:**
- `ArgumentError`: If text contains disallowed special tokens

**Example:**
```julia
enc = get_encoding("cl100k_base")

# Default: errors on special tokens
tokens = encode(enc, "hello world")

# Allow all special tokens
tokens = encode(enc, "<|endoftext|>hello", allowed_special=:all)

# Allow specific special tokens
tokens = encode(enc, "<|endoftext|>hello",
                allowed_special=Set(["<|endoftext|>"]))

# Don't error on any special tokens (encode as text)
tokens = encode(enc, "<|endoftext|>", disallowed_special=Set{String}())
```

#### `encode_ordinary(enc::Encoding, text::String) -> Vector{Int}`

Encode text, treating all special tokens as ordinary text (faster than `encode` with `disallowed_special=Set{String}()`).

**Parameters:**
- `text::String`: Text to encode

**Returns:**
- `Vector{Int}`: Token IDs

**Example:**
```julia
tokens = encode_ordinary(enc, "<|endoftext|>hello")
# Special token is encoded as regular text
```

#### `encode_batch(enc::Encoding, texts::Vector{String}; num_threads::Int=Threads.nthreads(), allowed_special::AllowedSpecial=Set{String}(), disallowed_special::DisallowedSpecial=:all) -> Vector{Vector{Int}}`

Encode multiple texts in parallel.

**Parameters:**
- `texts::Vector{String}`: Texts to encode
- `num_threads::Int`: Number of threads (default: Julia's thread count)
- `allowed_special`, `disallowed_special`: Same as `encode`

**Returns:**
- `Vector{Vector{Int}}`: Vector of token ID vectors

**Example:**
```julia
texts = ["hello world", "foo bar", "test"]
tokens = encode_batch(enc, texts, num_threads=4)
```

#### `encode_ordinary_batch(enc::Encoding, texts::Vector{String}; num_threads::Int=Threads.nthreads()) -> Vector{Vector{Int}}`

Encode multiple texts in parallel, ignoring special tokens.

**Parameters:**
- `texts::Vector{String}`: Texts to encode
- `num_threads::Int`: Number of threads

**Returns:**
- `Vector{Vector{Int}}`: Vector of token ID vectors

### Advanced Encoding Methods

#### `encode_with_unstable(enc::Encoding, text::String; allowed_special::AllowedSpecial=Set{String}(), disallowed_special::DisallowedSpecial=:all) -> Tuple{Vector{Int}, Vector{Vector{Int}}}`

Encode text, returning stable tokens and possible completions for incomplete sequences.

**Returns:**
- `Tuple{Vector{Int}, Vector{Vector{Int}}}`: (stable_tokens, completions)

**Example:**
```julia
tokens, completions = encode_with_unstable(enc, "hello")
```

#### `encode_single_token(enc::Encoding, text_or_bytes::Union{String, Vector{UInt8}}) -> Int`

Encode a single token, erroring if the text is not exactly one token.

**Parameters:**
- `text_or_bytes::Union{String, Vector{UInt8}}`: Single token as text or bytes

**Returns:**
- `Int`: Token ID

**Throws:**
- `ArgumentError`: If input is not exactly one token

**Example:**
```julia
token_id = encode_single_token(enc, "hello")
```

### Core Decoding Methods

#### `decode(enc::Encoding, tokens::Vector{Int}; errors::Symbol=:replace) -> String`

Decode tokens to text.

**Parameters:**
- `tokens::Vector{Int}`: Token IDs to decode
- `errors::Symbol`: How to handle invalid UTF-8
  - `:replace` - (default) Replace invalid sequences with �
  - `:strict` - Throw error on invalid UTF-8
  - `:ignore` - Remove invalid sequences

**Returns:**
- `String`: Decoded text

**Example:**
```julia
text = decode(enc, [15339, 1917])  # "hello world"

# Handle errors differently
text = decode(enc, tokens, errors=:strict)
```

#### `decode_bytes(enc::Encoding, tokens::Vector{Int}) -> Vector{UInt8}`

Decode tokens to raw bytes (no UTF-8 validation).

**Parameters:**
- `tokens::Vector{Int}`: Token IDs

**Returns:**
- `Vector{UInt8}`: Raw bytes

**Example:**
```julia
bytes = decode_bytes(enc, tokens)
```

#### `decode_batch(enc::Encoding, batch::Vector{Vector{Int}}; errors::Symbol=:replace, num_threads::Int=Threads.nthreads()) -> Vector{String}`

Decode multiple token sequences in parallel.

**Parameters:**
- `batch::Vector{Vector{Int}}`: Batch of token sequences
- `errors::Symbol`: Error handling mode
- `num_threads::Int`: Number of threads

**Returns:**
- `Vector{String}`: Decoded texts

**Example:**
```julia
texts = decode_batch(enc, [tokens1, tokens2, tokens3])
```

#### `decode_bytes_batch(enc::Encoding, batch::Vector{Vector{Int}}; num_threads::Int=Threads.nthreads()) -> Vector{Vector{UInt8}}`

Decode multiple token sequences to bytes in parallel.

### Advanced Decoding Methods

#### `decode_single_token_bytes(enc::Encoding, token::Int) -> Vector{UInt8}`

Decode a single token to bytes.

**Parameters:**
- `token::Int`: Token ID

**Returns:**
- `Vector{UInt8}`: Token bytes

**Example:**
```julia
bytes = decode_single_token_bytes(enc, 15339)
```

#### `decode_tokens_bytes(enc::Encoding, tokens::Vector{Int}) -> Vector{Vector{UInt8}}`

Decode tokens to a list of byte sequences (one per token).

**Parameters:**
- `tokens::Vector{Int}`: Token IDs

**Returns:**
- `Vector{Vector{UInt8}}`: Byte sequence for each token

**Example:**
```julia
byte_list = decode_tokens_bytes(enc, [15339, 1917])
# [[0x68, 0x65, 0x6c, 0x6c, 0x6f], [0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64]]
```

#### `decode_with_offsets(enc::Encoding, tokens::Vector{Int}) -> Tuple{String, Vector{Int}}`

Decode tokens and return character offsets for each token.

**Parameters:**
- `tokens::Vector{Int}`: Token IDs

**Returns:**
- `Tuple{String, Vector{Int}}`: (decoded_text, character_offsets)

**Example:**
```julia
text, offsets = decode_with_offsets(enc, tokens)
# ("hello world", [0, 5, 11])  # Offsets for start of each token
```

## Encoding Properties

Access encoding metadata:

```julia
# Encoding name
enc.name  # "o200k_base"

# Maximum token value
max_token_value(enc::Encoding) -> Int

# End-of-text token (if exists)
eot_token(enc::Encoding) -> Union{Int, Nothing}

# Vocabulary size
n_vocab(enc::Encoding) -> Int

# Special tokens
special_tokens_set(enc::Encoding) -> Set{String}

# All token byte values
token_byte_values(enc::Encoding) -> Vector{Vector{UInt8}}

# Check if token is special
is_special_token(enc::Encoding, token::Int) -> Bool
```

**Example:**
```julia
enc = get_encoding("cl100k_base")

println(enc.name)  # "cl100k_base"
println(max_token_value(enc))  # 100255
println(eot_token(enc))  # 100257
println(n_vocab(enc))  # 100256

if is_special_token(enc, 100257)
    println("This is a special token!")
end
```

## Custom Encodings

Create custom encodings programmatically:

```julia
# Constructor for custom encodings
Encoding(
    name::String;
    pat_str::String,
    mergeable_ranks::Dict{Vector{UInt8}, Int},
    special_tokens::Dict{String, Int},
    explicit_n_vocab::Union{Int, Nothing}=nothing
) -> Encoding
```

**Parameters:**
- `name::String`: Encoding identifier
- `pat_str::String`: Regex pattern for splitting text
- `mergeable_ranks::Dict{Vector{UInt8}, Int}`: BPE merge ranks
- `special_tokens::Dict{String, Int}`: Special token mapping
- `explicit_n_vocab::Union{Int, Nothing}`: Explicit vocabulary size (optional)

**Example:**
```julia
custom_enc = Encoding(
    "my_encoding",
    pat_str=raw"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
    mergeable_ranks=my_ranks,
    special_tokens=Dict("<|special|>" => 100000)
)
```

## Complete Example

```julia
using JikJoken

# Get an encoding
enc = get_encoding("o200k_base")

# Basic encoding/decoding
text = "hello world"
tokens = encode(enc, text)
decoded = decode(enc, tokens)
@assert decoded == text

# With special tokens
text_with_special = "<|endoftext|>Hello, world!"
tokens = encode(enc, text_with_special, allowed_special=:all)
decoded = decode(enc, tokens)

# Batch processing
texts = ["first text", "second text", "third text"]
all_tokens = encode_batch(enc, texts)
decoded_texts = decode_batch(enc, all_tokens)

# Get token count (for API usage)
function count_tokens(text::String, model::String="gpt-4o")
    enc = encoding_for_model(model)
    length(encode(enc, text))
end

println("Token count: ", count_tokens("Hello, world!"))

# Work with offsets
tokens = encode(enc, "hello world")
text, offsets = decode_with_offsets(enc, tokens)
println("Text: $text")
println("Offsets: $offsets")

# Model-specific encoding
gpt4_enc = encoding_for_model("gpt-4o")
tokens = encode(gpt4_enc, "Testing GPT-4")
```

## Implementation Notes

### Architecture

```
┌─────────────┐
│ Julia API   │  (JikJoken.jl)
├─────────────┤
│ C FFI Layer │  (api.jl)
├─────────────┤
│ Rust Core   │  (TikToken's src/)
└─────────────┘
```

### Rust FFI

The Rust code is exposed via C FFI:

1. **Rust side**: Expose functions with `#[no_mangle] pub extern "C"`
2. **Julia side**: Call using `ccall(:function_name, ReturnType, (ArgTypes,), args...)`
3. **Build**: Cargo builds `libjikjoken.{so,dylib,dll}`
4. **Load**: Julia loads the library at module initialization

### Memory Management

- **Rust owns encodings**: Julia holds opaque pointers
- **Finalization**: Use `finalizer` to call Rust cleanup functions
- **Strings**: Convert between Julia `String` and C `const char*`
- **Arrays**: Zero-copy when possible, marshal when necessary

### Thread Safety

- Rust core is thread-safe for encoding/decoding
- Batch operations use Julia's `Threads.@threads` or Rust's parallel encoding
- Encoding objects are immutable after creation

### Error Handling

- Rust errors converted to Julia exceptions
- `ccall` returns error codes, Julia wraps in exceptions
- Special token errors → `ArgumentError`
- Invalid UTF-8 → Handled via `errors` parameter

## Testing Strategy

### Test Coverage

1. **API compatibility**: Match TikToken's behavior exactly
2. **Encodings**: Test all standard encodings (gpt2, o200k_base, etc.)
3. **Edge cases**: Empty strings, special tokens, multi-byte UTF-8
4. **Property tests**: Roundtrip, offset correctness
5. **Performance**: Benchmark against Python TikToken
6. **Cross-validation**: Use TikToken test vectors

### Test Data Sources

- Reuse TikToken's test vectors
- Include jtokkit test data for cross-language validation
- Generate property-based tests (similar to Hypothesis)

## Differences from Python TikToken

| Python TikToken | JikJoken (Julia) | Reason |
|----------------|------------------|--------|
| `"all"` string | `:all` symbol | Julia convention for special values |
| `set()` | `Set{String}()` | Typed collections |
| `errors="replace"` | `errors=:replace` | Symbol for enum-like values |
| `None` | `nothing` | Julia's null value |
| Type hints | Concrete types | Julia's type system |
| `__init__` | Outer constructor | Julia constructors |
| Properties via `@property` | Functions like `eot_token(enc)` | Julia doesn't have properties for structs |

## Future Extensions

### Potential Additions

1. **Streaming API**: Encode/decode iterators for large files
2. **Validation**: Check token sequences for validity
3. **Serialization**: Save/load custom encodings
4. **Integration**: Work with Julia ML libraries (Flux.jl, etc.)
5. **BPE Training**: Train custom encodings (if needed)

### Plugin System

Similar to `tiktoken_ext`, allow registering custom encodings:

```julia
# Register custom encoding
JikJoken.register_encoding("my_custom_encoding", my_encoding_constructor)

# Use it
enc = get_encoding("my_custom_encoding")
```

## Version Compatibility

- **Julia**: 1.10+ (LTS and current stable)
- **Rust**: 1.85+ (for jlrs compatibility)
- **TikToken**: API compatible with TikToken 0.12.0

## License

Same as TikToken: MIT License

## References

- [TikToken Python API](https://github.com/openai/tiktoken)
- [Julia C FFI Documentation](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)
- [jlrs - Julia-Rust bindings](https://github.com/Taaitaaiger/jlrs)
- [JuliaPackageWithRustDep - Example](https://github.com/felipenoris/JuliaPackageWithRustDep.jl)
