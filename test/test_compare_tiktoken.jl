"""
Comparison tests against known TikToken outputs

These test vectors are from tiktoken's test suite to ensure
we produce identical results.
"""

using JikJoken
using Test

@testset "Known token values" begin
    @testset "GPT-2 specific tokens" begin
        enc = get_encoding("gpt2")

        # These are known token values from tiktoken
        # Test a few specific encodings to verify correctness
        test_cases = [
            ("hello", [31373]),
            (" hello", [23748]),
            ("Hello", [15496]),
            (" Hello", [18435]),
        ]

        for (text, expected_tokens) in test_cases
            tokens = encode(enc, text)
            @test tokens == expected_tokens
        end
    end

    @testset "Common words" begin
        enc = get_encoding("cl100k_base")

        # Test that we can encode and decode common patterns
        # (Exact token values may vary, but roundtrip must work)
        texts = [
            "the",
            "a",
            "is",
            "at",
            "which",
            "on",
        ]

        for text in texts
            tokens = encode(enc, text)
            decoded = decode(enc, tokens)
            @test decoded == text
            @test length(tokens) >= 1
        end
    end
end
