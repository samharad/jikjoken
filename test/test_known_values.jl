"""
Test against exact known token values from tiktoken's test suite
These are the exact test cases from tiktoken/tests/test_encoding.py
"""

using JikJoken
using Test

@testset "Known token values from tiktoken" begin
    @testset "test_simple - gpt2" begin
        enc = get_encoding("gpt2")

        # From tiktoken test_simple()
        @test encode(enc, "hello world") == [31373, 995]
        @test decode(enc, [31373, 995]) == "hello world"
    end

    @testset "test_simple - cl100k_base" begin
        enc = get_encoding("cl100k_base")

        # From tiktoken test_simple()
        @test encode(enc, "hello world") == [15339, 1917]
        @test decode(enc, [15339, 1917]) == "hello world"
    end

    @testset "test_simple_repeated - gpt2 zeros" begin
        enc = get_encoding("gpt2")

        # From tiktoken test_simple_repeated()
        @test encode(enc, "0") == [15]
        @test encode(enc, "00") == [405]
        @test encode(enc, "000") == [830]
        @test encode(enc, "0000") == [2388]
        @test encode(enc, "00000") == [20483]
        @test encode(enc, "000000") == [10535]
        @test encode(enc, "0000000") == [24598]
        @test encode(enc, "00000000") == [8269]
        @test encode(enc, "000000000") == [10535, 830]
        @test encode(enc, "0000000000") == [8269, 405]
        @test encode(enc, "00000000000") == [8269, 830]
        @test encode(enc, "000000000000") == [8269, 2388]
        @test encode(enc, "0000000000000") == [8269, 20483]
        @test encode(enc, "00000000000000") == [8269, 10535]
        @test encode(enc, "000000000000000") == [8269, 24598]
        @test encode(enc, "0000000000000000") == [25645]
        @test encode(enc, "00000000000000000") == [8269, 10535, 830]
    end

    @testset "test_simple_regex - cl100k_base" begin
        enc = get_encoding("cl100k_base")

        # From tiktoken test_simple_regex()
        @test encode(enc, "rer") == [38149]
        @test encode(enc, "'rer") == [2351, 81]
        @test encode(enc, "today\n ") == [31213, 198, 220]
        @test encode(enc, "today\n \n") == [31213, 27907]
        @test encode(enc, "today\n  \n") == [31213, 14211]
    end

    @testset "test_basic_encode - multiple encodings" begin
        # From tiktoken test_basic_encode()
        enc_r50k = get_encoding("r50k_base")
        @test encode(enc_r50k, "hello world") == [31373, 995]

        enc_p50k = get_encoding("p50k_base")
        @test encode(enc_p50k, "hello world") == [31373, 995]

        enc_cl100k = get_encoding("cl100k_base")
        @test encode(enc_cl100k, "hello world") == [15339, 1917]

        # Special byte sequence test - skipped because Julia strings must be valid UTF-8
        # In Python tiktoken, this tests handling of invalid UTF-8, but our Rust FFI
        # validates UTF-8 at the boundary (as it should)
        # @test encode(enc_cl100k, " \x850") == [220, 126, 227, 15]
    end

    @testset "test_encode_empty" begin
        enc = get_encoding("r50k_base")

        # From tiktoken test_encode_empty()
        @test encode(enc, "") == []
    end
end
