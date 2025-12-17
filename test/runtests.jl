using JikJoken
using Test

@testset "JikJoken.jl" begin
    @testset "Basic roundtrip" begin
        # This mirrors Python's test_simple() from tiktoken
        enc = get_encoding("gpt2")

        # Simple roundtrip test
        text = "hello world"
        tokens = encode(enc, text)
        decoded = decode(enc, tokens)

        @test decoded == text
        @test length(tokens) > 0
    end

    @testset "Library version" begin
        version = JikJoken.jikjoken_version()
        @test version isa String
        @test startswith(version, "0.1.")
    end
end
