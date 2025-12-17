"""
Basic encoding/decoding tests
Mirrors tiktoken's test_encoding.py::test_simple()
"""

using JikJoken
using Test

@testset "Basic encoding tests" begin
    @testset "Simple roundtrip - gpt2" begin
        enc = get_encoding("gpt2")

        # Basic roundtrip
        text = "hello world"
        tokens = encode(enc, text)
        decoded = decode(enc, tokens)

        @test decoded == text
        @test length(tokens) > 0
    end

    @testset "Simple roundtrip - cl100k_base" begin
        enc = get_encoding("cl100k_base")

        text = "hello world"
        tokens = encode(enc, text)
        decoded = decode(enc, tokens)

        @test decoded == text
    end

    @testset "Empty string" begin
        enc = get_encoding("gpt2")

        tokens = encode(enc, "")
        @test length(tokens) == 0

        decoded = decode(enc, tokens)
        @test decoded == ""
    end

    @testset "Single character" begin
        enc = get_encoding("gpt2")

        text = "a"
        tokens = encode(enc, text)
        decoded = decode(enc, tokens)

        @test decoded == text
        @test length(tokens) >= 1
    end

    @testset "Longer text" begin
        enc = get_encoding("gpt2")

        text = "The quick brown fox jumps over the lazy dog."
        tokens = encode(enc, text)
        decoded = decode(enc, tokens)

        @test decoded == text
        @test length(tokens) > 5
    end

    @testset "Unicode text" begin
        enc = get_encoding("cl100k_base")

        # Test various Unicode characters
        texts = [
            "Hello, 世界!",
            "Привет мир",
            "مرحبا بالعالم",
            "こんにちは世界",
            "🌍🌎🌏",
        ]

        for text in texts
            tokens = encode(enc, text)
            decoded = decode(enc, tokens)
            @test decoded == text
        end
    end

    @testset "Whitespace handling" begin
        enc = get_encoding("gpt2")

        texts = [
            "  hello  ",
            "\n\n\nhello\n\n\n",
            "\t\thello\t\t",
            "hello\r\nworld",
        ]

        for text in texts
            tokens = encode(enc, text)
            decoded = decode(enc, tokens)
            @test decoded == text
        end
    end

    @testset "Repetitive text" begin
        enc = get_encoding("gpt2")

        # Test very repetitive input (tests caching behavior)
        text = "a" ^ 100
        tokens = encode(enc, text)
        decoded = decode(enc, tokens)

        @test decoded == text
    end
end
