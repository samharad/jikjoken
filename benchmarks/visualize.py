#!/usr/bin/env python3
"""
Create performance comparison visualization.
"""

import json
import sys
from pathlib import Path


def create_visualization(jikjoken_file: str, tiktoken_file: str, output_file: str = "performance_comparison.md"):
    """Create a markdown visualization of benchmark results."""

    # Load results
    with open(jikjoken_file) as f:
        jikjoken = json.load(f)

    with open(tiktoken_file) as f:
        tiktoken = json.load(f)

    # Calculate speedup
    speedup = tiktoken["mean_throughput_mb_s"] / jikjoken["mean_throughput_mb_s"]

    # Create markdown visualization
    md = f"""# Performance Comparison: JikJoken vs tiktoken

## Benchmark Setup

- **Text corpus**: {jikjoken['text_size_mb']:.2f} MB ({jikjoken['text_size_mb']/1024:.2f} GB)
- **Tokenizer**: GPT-2
- **Number of runs**: {jikjoken['num_runs']}

## Results

| Library | Language | Mean Time | Throughput | Relative Performance |
|---------|----------|-----------|------------|---------------------|
| **JikJoken** | Julia | {jikjoken['mean_time']:.3f}s | **{jikjoken['mean_throughput_mb_s']:.2f} MB/s** | **{1/speedup:.2f}x faster** |
| tiktoken | Python | {tiktoken['mean_time']:.3f}s | {tiktoken['mean_throughput_mb_s']:.2f} MB/s | 1.00x (baseline) |

## Throughput Comparison

```
JikJoken (Julia)  {'█' * int(jikjoken['mean_throughput_mb_s'] * 5)} {jikjoken['mean_throughput_mb_s']:.2f} MB/s
tiktoken (Python) {'█' * int(tiktoken['mean_throughput_mb_s'] * 5)} {tiktoken['mean_throughput_mb_s']:.2f} MB/s
```

*Each █ represents ~0.2 MB/s*

## Detailed Statistics

### JikJoken (Julia)
- Mean time: {jikjoken['mean_time']:.3f}s
- Min time: {jikjoken['min_time']:.3f}s
- Max time: {jikjoken['max_time']:.3f}s
- Throughput: {jikjoken['mean_throughput_mb_s']:.2f} MB/s
- Tokens processed: {jikjoken['token_counts'][0]:,}

### tiktoken (Python)
- Mean time: {tiktoken['mean_time']:.3f}s
- Min time: {tiktoken['min_time']:.3f}s
- Max time: {tiktoken['max_time']:.3f}s
- Throughput: {tiktoken['mean_throughput_mb_s']:.2f} MB/s
- Tokens processed: {tiktoken['token_counts'][0]:,}

## Summary

JikJoken is **{abs(1/speedup - 1)*100:.1f}% {'faster' if speedup < 1 else 'slower'}** than tiktoken when processing large text corpora.

Both libraries are built on the same Rust core (tiktoken_core), so the performance difference is primarily due to:
- FFI overhead differences between Julia ccall and Python ctypes/CFFI
- Memory management strategies
- Language runtime characteristics
"""

    # Write markdown file
    with open(output_file, 'w') as f:
        f.write(md)

    print(f"Visualization saved to: {output_file}")
    print("\n" + "="*60)
    print(md)


if __name__ == "__main__":
    jikjoken_file = sys.argv[1] if len(sys.argv) > 1 else "results_jikjoken.json"
    tiktoken_file = sys.argv[2] if len(sys.argv) > 2 else "results_tiktoken.json"
    output_file = sys.argv[3] if len(sys.argv) > 3 else "performance_comparison.md"

    if not Path(jikjoken_file).exists():
        print(f"Error: JikJoken results file not found: {jikjoken_file}")
        sys.exit(1)

    if not Path(tiktoken_file).exists():
        print(f"Error: tiktoken results file not found: {tiktoken_file}")
        sys.exit(1)

    create_visualization(jikjoken_file, tiktoken_file, output_file)
