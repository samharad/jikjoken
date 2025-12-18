#!/usr/bin/env julia
"""
Benchmark JikJoken tokenization performance.
Tests on 1GB of text using GPT-2 tokenizer.
"""

using JikJoken
using JSON3

function benchmark_jikjoken(input_file::String, num_runs::Int=3)
    println("Loading test data...")
    text = read(input_file, String)
    text_size_mb = sizeof(text) / 1024^2

    println("Text size: $(round(text_size_mb, digits=2)) MB")
    println("Initializing GPT-2 encoding...")

    enc = get_encoding("gpt2")

    println("\nWarming up...")
    # Warm-up run
    tokens = encode(enc, text[1:min(10000, length(text))])
    println("Warm-up complete. Encoded $(length(tokens)) tokens.")

    println("\nRunning benchmark ($(num_runs) runs)...")

    times = Float64[]
    token_counts = Int[]

    for i in 1:num_runs
        println("\nRun $i/$num_runs:")

        # Force garbage collection before timing
        GC.gc()

        # Time the encoding
        start_time = time()
        tokens = encode(enc, text)
        elapsed = time() - start_time

        push!(times, elapsed)
        push!(token_counts, length(tokens))

        throughput_mb_s = text_size_mb / elapsed

        println("  Time: $(round(elapsed, digits=3))s")
        println("  Tokens: $(length(tokens))")
        println("  Throughput: $(round(throughput_mb_s, digits=2)) MB/s")
    end

    # Calculate statistics
    mean_time = sum(times) / length(times)
    min_time = minimum(times)
    max_time = maximum(times)
    mean_throughput = text_size_mb / mean_time

    results = Dict(
        "library" => "JikJoken",
        "language" => "Julia",
        "tokenizer" => "gpt2",
        "text_size_mb" => text_size_mb,
        "num_runs" => num_runs,
        "times_seconds" => times,
        "token_counts" => token_counts,
        "mean_time" => mean_time,
        "min_time" => min_time,
        "max_time" => max_time,
        "mean_throughput_mb_s" => mean_throughput,
    )

    println("\n" * "="^60)
    println("BENCHMARK RESULTS")
    println("="^60)
    println("Library: JikJoken (Julia)")
    println("Tokenizer: GPT-2")
    println("Text size: $(round(text_size_mb, digits=2)) MB")
    println("Number of runs: $num_runs")
    println("\nTiming:")
    println("  Mean: $(round(mean_time, digits=3))s")
    println("  Min:  $(round(min_time, digits=3))s")
    println("  Max:  $(round(max_time, digits=3))s")
    println("\nThroughput:")
    println("  $(round(mean_throughput, digits=2)) MB/s")
    println("="^60)

    return results
end

function save_results(results::Dict, output_file::String)
    open(output_file, "w") do io
        JSON3.write(io, results)
    end
    println("\nResults saved to: $output_file")
end

if abspath(PROGRAM_FILE) == @__FILE__
    input_file = get(ARGS, 1, "test_data_1gb.txt")
    output_file = get(ARGS, 2, "results_jikjoken.json")
    num_runs = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 3

    if !isfile(input_file)
        println("Error: Input file not found: $input_file")
        println("Generate it first with: julia generate_data.jl")
        exit(1)
    end

    results = benchmark_jikjoken(input_file, num_runs)
    save_results(results, output_file)
end
