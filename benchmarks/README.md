# JikJoken Performance Benchmarks

This directory contains performance benchmarking tools for comparing JikJoken (Julia) against tiktoken (Python).

## Quick Start

Run the complete benchmark suite:

```bash
./run_all.sh
```

This will:
1. Generate test data (1GB by default)
2. Benchmark JikJoken
3. Benchmark tiktoken
4. Generate a comparison visualization

## Individual Scripts

### Generate Test Data

```bash
julia generate_data.jl <output_file> <size_in_gb>
```

Example:
```bash
julia generate_data.jl test_data_1gb.txt 1.0
```

### Benchmark JikJoken

```bash
julia --project=.. bench_jikjoken.jl <input_file> <output_json> <num_runs>
```

Example:
```bash
julia --project=.. bench_jikjoken.jl test_data_1gb.txt results_jikjoken.json 3
```

### Benchmark tiktoken

```bash
python3 bench_tiktoken.py <input_file> <output_json> <num_runs>
```

Example:
```bash
python3 bench_tiktoken.py test_data_1gb.txt results_tiktoken.json 3
```

### Generate Visualization

```bash
python3 visualize.py <jikjoken_results> <tiktoken_results> <output_md>
```

Example:
```bash
python3 visualize.py results_jikjoken.json results_tiktoken.json performance_comparison.md
```

## Latest Results

See [performance_comparison.md](performance_comparison.md) for the latest benchmark comparison.

## Methodology

Following the methodology from [tiktoken's README](https://github.com/openai/tiktoken#performance):
- Test corpus: Diverse text samples (code, natural language, technical docs, etc.)
- Tokenizer: GPT-2 (r50k_base)
- Metrics: Throughput in MB/s, total encoding time
- Multiple runs: 3 runs per benchmark to account for variance
