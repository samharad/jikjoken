using JikJoken
using Test

@testset "JikJoken.jl" begin
    @testset "Library version" begin
        version = JikJoken.jikjoken_version()
        @test version isa String
        @test startswith(version, "0.1.")
    end

    # Run all test files
    include("test_basic.jl")
    include("test_registry.jl")
    include("test_compare_tiktoken.jl")
    include("test_known_values.jl")
end
