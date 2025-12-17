"""
    Encoding

Represents a BPE tokenization scheme.
"""
mutable struct Encoding
    name::String
    handle::Ptr{Cvoid}  # Opaque pointer to Rust CoreBPE

    # Constructor that sets up finalizer
    function Encoding(name::String, handle::Ptr{Cvoid})
        enc = new(name, handle)
        finalizer(enc) do e
            if e.handle != C_NULL
                jikjoken_encoding_free(e.handle)
                e.handle = C_NULL
            end
        end
        return enc
    end
end

"""
Error codes from Rust FFI
"""
@enum FFIError::Int32 begin
    Success = 0
    NullPointer = 1
    InvalidUtf8 = 2
    InvalidToken = 3
    EncodeError = 4
    DecodeError = 5
    AllocationError = 6
end

"""
Token array returned from encoding operations
"""
struct TokenArray
    tokens::Ptr{UInt32}
    length::UInt64
end
