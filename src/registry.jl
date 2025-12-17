"""
Encoding registry - loading encodings from tiktoken data files
"""

using JSON3

# Mapping of encoding names to tiktoken files
const ENCODING_FILES = Dict(
    "gpt2" => "https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken",
    "r50k_base" => "https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken",
    "p50k_base" => "https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken",
    "cl100k_base" => "https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken",
    "o200k_base" => "https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken",
)

# Regex patterns for each encoding
const ENCODING_PATTERNS = Dict(
    "gpt2" => raw"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
    "r50k_base" => raw"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
    "p50k_base" => raw"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
    "cl100k_base" => raw"(?i:'s|'t|'re|'ve|'m|'ll|'d)|[^\r\n\p{L}\p{N}]?\p{L}+|\p{N}{1,3}| ?[^\s\p{L}\p{N}]+[\r\n]*|\s*[\r\n]+|\s+(?!\S)|\s+",
    "o200k_base" => raw"[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]*[\p{Ll}\p{Lm}\p{Lo}\p{M}]+(?i:'s|'t|'re|'ve|'m|'ll|'d)?|[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]+[\p{Ll}\p{Lm}\p{Lo}\p{M}]*(?i:'s|'t|'re|'ve|'m|'ll|'d)?|\p{N}{1,3}| ?[^\s\p{L}\p{N}]+[\r\n/]*|\s*[\r\n]+|\s+(?!\S)|\s+",
)

# Special tokens for each encoding
const SPECIAL_TOKENS = Dict(
    "gpt2" => Dict("<|endoftext|>" => 50256),
    "r50k_base" => Dict("<|endoftext|>" => 50256),
    "p50k_base" => Dict("<|endoftext|>" => 50256),
    "cl100k_base" => Dict(
        "<|endoftext|>" => 100257,
        "<|fim_prefix|>" => 100258,
        "<|fim_middle|>" => 100259,
        "<|fim_suffix|>" => 100260,
        "<|endofprompt|>" => 100276
    ),
    "o200k_base" => Dict(
        "<|endoftext|>" => 199999,
        "<|endofprompt|>" => 200018
    ),
)

# Model to encoding mapping
const MODEL_TO_ENCODING = Dict(
    "gpt-4" => "cl100k_base",
    "gpt-4-turbo" => "cl100k_base",
    "gpt-4o" => "o200k_base",
    "gpt-4o-mini" => "o200k_base",
    "gpt-3.5-turbo" => "cl100k_base",
    "gpt-3" => "p50k_base",
    "text-davinci-003" => "p50k_base",
    "text-davinci-002" => "p50k_base",
)

"""
    get_encoding(name::String) -> Encoding

Get an encoding by name.

# Arguments
- `name::String`: Encoding name (e.g., "gpt2", "cl100k_base", "o200k_base")

# Examples
```julia
enc = get_encoding("gpt2")
```
"""
function get_encoding(name::String)
    if !haskey(ENCODING_FILES, name)
        error("Unknown encoding: $name. Available: $(join(keys(ENCODING_FILES), ", "))")
    end

    # Load or download the tiktoken file
    tiktoken_data = load_tiktoken_data(name)

    # Get pattern and special tokens
    pattern = ENCODING_PATTERNS[name]
    special_tokens = SPECIAL_TOKENS[name]

    # Create encoding via FFI
    handle = create_encoding_ffi(tiktoken_data, special_tokens, pattern)

    return Encoding(name, handle)
end

"""
    encoding_for_model(model_name::String) -> Encoding

Get the appropriate encoding for a specific model.

# Examples
```julia
enc = encoding_for_model("gpt-4o")
```
"""
function encoding_for_model(model_name::String)
    # Check for exact match
    if haskey(MODEL_TO_ENCODING, model_name)
        return get_encoding(MODEL_TO_ENCODING[model_name])
    end

    # Try prefix matching
    for (model_prefix, encoding_name) in MODEL_TO_ENCODING
        if startswith(model_name, model_prefix)
            return get_encoding(encoding_name)
        end
    end

    error("Unknown model: $model_name")
end

"""
Load tiktoken data from cache or download it.
"""
function load_tiktoken_data(name::String)
    cache_dir = joinpath(homedir(), ".cache", "jikjoken")
    mkpath(cache_dir)

    cache_file = joinpath(cache_dir, "$(name).tiktoken")

    # Use cached file if it exists
    if isfile(cache_file)
        return read(cache_file)
    end

    # Download from URL
    url = ENCODING_FILES[name]
    @info "Downloading encoding data for $name from $url"

    # Use curl to download (more reliable than Julia's download in some environments)
    run(pipeline(`curl -L -o $cache_file $url`, stderr=devnull))

    return read(cache_file)
end

"""
Parse tiktoken file format and create encoding via FFI.
"""
function create_encoding_ffi(tiktoken_bytes::Vector{UInt8}, special_tokens::Dict{String,Int}, pattern::String)
    # Parse tiktoken format (each line is: base64_token rank)
    lines = split(String(tiktoken_bytes), '\n')

    mergeable_ranks = Dict{Vector{UInt8}, UInt32}()

    for line in lines
        isempty(strip(line)) && continue

        parts = split(line, ' ')
        if length(parts) != 2
            continue
        end

        # Decode base64 token
        token_bytes = base64decode(parts[1])
        rank = parse(UInt32, parts[2])

        mergeable_ranks[token_bytes] = rank
    end

    @info "Loaded $(length(mergeable_ranks)) tokens"

    # Call Rust FFI to create encoding
    # Convert data to C-compatible format
    encoder_keys = [pointer(k) for k in keys(mergeable_ranks)]
    encoder_key_lens = [length(k) for k in keys(mergeable_ranks)]
    encoder_values = collect(UInt32, values(mergeable_ranks))

    special_keys = [pointer(Vector{UInt8}(k)) for k in keys(special_tokens)]
    special_values = collect(UInt32, values(special_tokens))

    out_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)

    result = ccall(
        (:jikjoken_encoding_new, LIBJIKJOKEN),
        Int32,
        (Ptr{Ptr{UInt8}}, Ptr{UInt64}, Ptr{UInt32}, UInt64,
         Ptr{Cstring}, Ptr{UInt32}, UInt64,
         Cstring, Ptr{Ptr{Cvoid}}),
        encoder_keys, encoder_key_lens, encoder_values, length(encoder_keys),
        special_keys, special_values, length(special_keys),
        pattern, out_handle_ref
    )

    if result != Int32(Success)
        error("Failed to create encoding with error code: $result")
    end

    return out_handle_ref[]
end

# Helper function for base64 decoding
function base64decode(s::AbstractString)
    # Use Julia's base64 decoder
    return Base64.base64decode(s)
end
