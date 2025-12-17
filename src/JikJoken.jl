module JikJoken

# Export main API functions
export get_encoding, encoding_for_model, encode, decode, encode_ordinary

# Core types
include("types.jl")
include("ffi.jl")
include("encoding.jl")
include("registry.jl")

end # module
