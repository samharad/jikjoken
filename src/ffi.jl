"""
Low-level FFI bindings to the Rust library
"""

# Path to the shared library
const LIBJIKJOKEN = joinpath(@__DIR__, "..", "deps", "jikjoken-sys", "target", "release", "libjikjoken.so")

"""
    jikjoken_encoding_free(handle::Ptr{Cvoid})

Free an encoding handle.
"""
function jikjoken_encoding_free(handle::Ptr{Cvoid})
    ccall((:jikjoken_encoding_free, LIBJIKJOKEN), Cvoid, (Ptr{Cvoid},), handle)
end

"""
    jikjoken_encode_ordinary(handle::Ptr{Cvoid}, text::String) -> Vector{UInt32}

Encode text without special token handling.
"""
function jikjoken_encode_ordinary(handle::Ptr{Cvoid}, text::String)
    out_tokens_ref = Ref{Ptr{TokenArray}}(C_NULL)

    result = ccall(
        (:jikjoken_encode_ordinary, LIBJIKJOKEN),
        Int32,
        (Ptr{Cvoid}, Cstring, Ptr{Ptr{TokenArray}}),
        handle, text, out_tokens_ref
    )

    if result != Int32(Success)
        error("Encoding failed with error code: $result")
    end

    token_array_ptr = out_tokens_ref[]
    if token_array_ptr == C_NULL
        error("Null token array returned")
    end

    # Read the TokenArray struct
    token_array = unsafe_load(token_array_ptr)

    # Copy tokens to Julia array
    tokens = unsafe_wrap(Vector{UInt32}, token_array.tokens, token_array.length; own=false)
    result_tokens = copy(tokens)

    # Free the token array
    jikjoken_tokens_free(token_array_ptr)

    return result_tokens
end

"""
    jikjoken_tokens_free(tokens::Ptr{TokenArray})

Free a token array.
"""
function jikjoken_tokens_free(tokens::Ptr{TokenArray})
    ccall((:jikjoken_tokens_free, LIBJIKJOKEN), Cvoid, (Ptr{TokenArray},), tokens)
end

"""
    jikjoken_decode_bytes(handle::Ptr{Cvoid}, tokens::Vector{UInt32}) -> Vector{UInt8}

Decode tokens to bytes.
"""
function jikjoken_decode_bytes(handle::Ptr{Cvoid}, tokens::Vector{UInt32})
    out_bytes_ref = Ref{Ptr{UInt8}}(C_NULL)
    out_length_ref = Ref{UInt64}(0)

    result = ccall(
        (:jikjoken_decode_bytes, LIBJIKJOKEN),
        Int32,
        (Ptr{Cvoid}, Ptr{UInt32}, UInt64, Ptr{Ptr{UInt8}}, Ptr{UInt64}),
        handle, tokens, length(tokens), out_bytes_ref, out_length_ref
    )

    if result != Int32(Success)
        error("Decoding failed with error code: $result")
    end

    bytes_ptr = out_bytes_ref[]
    bytes_len = out_length_ref[]

    if bytes_ptr == C_NULL
        return UInt8[]
    end

    # Copy bytes to Julia array
    bytes = unsafe_wrap(Vector{UInt8}, bytes_ptr, bytes_len; own=false)
    result_bytes = copy(bytes)

    # Free the byte array
    jikjoken_bytes_free(bytes_ptr, bytes_len)

    return result_bytes
end

"""
    jikjoken_bytes_free(bytes::Ptr{UInt8}, length::UInt64)

Free a byte array.
"""
function jikjoken_bytes_free(bytes::Ptr{UInt8}, length::UInt64)
    ccall((:jikjoken_bytes_free, LIBJIKJOKEN), Cvoid, (Ptr{UInt8}, UInt64), bytes, length)
end

"""
    jikjoken_version() -> String

Get the library version.
"""
function jikjoken_version()
    version_ptr = ccall((:jikjoken_version, LIBJIKJOKEN), Cstring, ())
    return unsafe_string(version_ptr)
end
