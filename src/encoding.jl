"""
High-level encoding operations
"""

"""
    encode_ordinary(enc::Encoding, text::String) -> Vector{Int}

Encode text, treating all special tokens as ordinary text.

This is faster than `encode` with `disallowed_special=Set{String}()`.

# Examples
```julia
enc = get_encoding("gpt2")
tokens = encode_ordinary(enc, "Hello, world!")
```
"""
function encode_ordinary(enc::Encoding, text::String)
    return Int.(jikjoken_encode_ordinary(enc.handle, text))
end

"""
    encode(enc::Encoding, text::String) -> Vector{Int}

Encode text to tokens.

Currently only supports ordinary encoding (no special token control yet).

# Examples
```julia
enc = get_encoding("gpt2")
tokens = encode(enc, "Hello, world!")
```
"""
function encode(enc::Encoding, text::String)
    # For now, just call encode_ordinary
    # TODO: Add special token support
    return encode_ordinary(enc, text)
end

"""
    decode(enc::Encoding, tokens::Vector{Int}; errors::Symbol=:replace) -> String

Decode tokens to text.

# Arguments
- `enc::Encoding`: The encoding to use
- `tokens::Vector{Int}`: Token IDs to decode
- `errors::Symbol`: How to handle invalid UTF-8 (`:replace`, `:strict`, `:ignore`)

# Examples
```julia
enc = get_encoding("gpt2")
text = decode(enc, [15496, 11, 995, 0])  # "Hello, world!"
```
"""
function decode(enc::Encoding, tokens::Vector{Int}; errors::Symbol=:replace)
    bytes = jikjoken_decode_bytes(enc.handle, UInt32.(tokens))

    if errors == :replace
        return String(bytes)  # Julia's String constructor handles replacement
    elseif errors == :strict
        # Check if valid UTF-8
        try
            str = String(bytes)
            # Verify it's valid UTF-8
            for c in str; end  # Will throw if invalid
            return str
        catch
            error("Invalid UTF-8 sequence")
        end
    elseif errors == :ignore
        # Remove invalid bytes
        return String(filter(isvalid, bytes))
    else
        error("Unknown error handling mode: $errors")
    end
end
