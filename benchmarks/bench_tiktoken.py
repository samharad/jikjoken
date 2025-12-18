#!/usr/bin/env python3
"""
Benchmark tiktoken (Python) tokenization performance.
Tests on 1GB of text using GPT-2 tokenizer.
"""

import json
import sys
import time
import gc
from pathlib import Path


def benchmark_tiktoken(input_file: str, num_runs: int = 3):
    try:
        import tiktoken
    except ImportError:
        print("Error: tiktoken not installed. Install with: pip install tiktoken")
        sys.exit(1)

    print("Loading test data...")
    with open(input_file, 'r', encoding='utf-8') as f:
        text = f.read()

    text_size_mb = len(text.encode('utf-8')) / (1024**2)

    print(f"Text size: {text_size_mb:.2f} MB")
    print("Initializing GPT-2 encoding...")

    enc = tiktoken.get_encoding("gpt2")

    print("\nWarming up...")
    # Warm-up run
    tokens = enc.encode(text[:min(10000, len(text))])
    print(f"Warm-up complete. Encoded {len(tokens)} tokens.")

    print(f"\nRunning benchmark ({num_runs} runs)...")

    times = []
    token_counts = []

    for i in range(num_runs):
        print(f"\nRun {i+1}/{num_runs}:")

        # Force garbage collection before timing
        gc.collect()

        # Time the encoding
        start_time = time.perf_counter()
        tokens = enc.encode(text)
        elapsed = time.perf_counter() - start_time

        times.append(elapsed)
        token_counts.append(len(tokens))

        throughput_mb_s = text_size_mb / elapsed

        print(f"  Time: {elapsed:.3f}s")
        print(f"  Tokens: {len(tokens)}")
        print(f"  Throughput: {throughput_mb_s:.2f} MB/s")

    # Calculate statistics
    mean_time = sum(times) / len(times)
    min_time = min(times)
    max_time = max(times)
    mean_throughput = text_size_mb / mean_time

    results = {
        "library": "tiktoken",
        "language": "Python",
        "tokenizer": "gpt2",
        "text_size_mb": text_size_mb,
        "num_runs": num_runs,
        "times_seconds": times,
        "token_counts": token_counts,
        "mean_time": mean_time,
        "min_time": min_time,
        "max_time": max_time,
        "mean_throughput_mb_s": mean_throughput,
    }

    print("\n" + "="*60)
    print("BENCHMARK RESULTS")
    print("="*60)
    print("Library: tiktoken (Python)")
    print("Tokenizer: GPT-2")
    print(f"Text size: {text_size_mb:.2f} MB")
    print(f"Number of runs: {num_runs}")
    print("\nTiming:")
    print(f"  Mean: {mean_time:.3f}s")
    print(f"  Min:  {min_time:.3f}s")
    print(f"  Max:  {max_time:.3f}s")
    print("\nThroughput:")
    print(f"  {mean_throughput:.2f} MB/s")
    print("="*60)

    return results


def save_results(results: dict, output_file: str):
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"\nResults saved to: {output_file}")


if __name__ == "__main__":
    input_file = sys.argv[1] if len(sys.argv) > 1 else "test_data_1gb.txt"
    output_file = sys.argv[2] if len(sys.argv) > 2 else "results_tiktoken.json"
    num_runs = int(sys.argv[3]) if len(sys.argv) > 3 else 3

    if not Path(input_file).exists():
        print(f"Error: Input file not found: {input_file}")
        print("Generate it first with: julia generate_data.jl")
        sys.exit(1)

    results = benchmark_tiktoken(input_file, num_runs)
    save_results(results, output_file)
