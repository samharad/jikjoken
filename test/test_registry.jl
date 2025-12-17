"""
Test encoding registry functionality
"""

using JikJoken
using Test

@testset "Encoding registry" begin
    @testset "get_encoding for all encodings" begin
        encodings = ["gpt2", "r50k_base", "p50k_base", "cl100k_base", "o200k_base"]

        for name in encodings
            @test_nowarn enc = get_encoding(name)
            enc = get_encoding(name)
            @test enc.name == name
            @test enc.handle != C_NULL
        end
    end

    @testset "encoding_for_model" begin
        models = [
            ("gpt-4", "cl100k_base"),
            ("gpt-4-turbo", "cl100k_base"),
            ("gpt-4o", "o200k_base"),
            ("gpt-4o-mini", "o200k_base"),
            ("gpt-3.5-turbo", "cl100k_base"),
        ]

        for (model, expected_encoding) in models
            enc = encoding_for_model(model)
            @test enc.name == expected_encoding
        end
    end

    @testset "Unknown encoding" begin
        @test_throws ErrorException get_encoding("nonexistent_encoding")
    end

    @testset "Unknown model" begin
        @test_throws ErrorException encoding_for_model("nonexistent_model")
    end

    @testset "Encoding reuse" begin
        # Getting the same encoding multiple times should work
        enc1 = get_encoding("gpt2")
        enc2 = get_encoding("gpt2")

        # They are different Julia objects but should work the same
        text = "hello world"
        tokens1 = encode(enc1, text)
        tokens2 = encode(enc2, text)

        @test tokens1 == tokens2
    end
end
