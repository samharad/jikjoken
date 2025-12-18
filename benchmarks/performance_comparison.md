# Performance Comparison: JikJoken vs tiktoken

## Benchmark Setup

- **Text corpus**: 102.40 MB (0.10 GB)
- **Tokenizer**: GPT-2
- **Number of runs**: 3

## Results

| Library | Language | Mean Time | Throughput | Relative Performance |
|---------|----------|-----------|------------|---------------------|
| **JikJoken** | Julia | 14.116s | **7.25 MB/s** | **0.81x faster** |
| tiktoken | Python | 11.432s | 8.96 MB/s | 1.00x (baseline) |

## Throughput Comparison

```
JikJoken (Julia)  ████████████████████████████████████ 7.25 MB/s
tiktoken (Python) ████████████████████████████████████████████ 8.96 MB/s
```

*Each █ represents ~0.2 MB/s*

## Detailed Statistics

### JikJoken (Julia)
- Mean time: 14.116s
- Min time: 14.076s
- Max time: 14.188s
- Throughput: 7.25 MB/s
- Tokens processed: 36,524,992

### tiktoken (Python)
- Mean time: 11.432s
- Min time: 11.346s
- Max time: 11.576s
- Throughput: 8.96 MB/s
- Tokens processed: 36,524,992

## Summary

JikJoken is **19.0% slower** than tiktoken when processing large text corpora.

Both libraries are built on the same Rust core (tiktoken_core), so the performance difference is primarily due to:
- FFI overhead differences between Julia ccall and Python ctypes/CFFI
- Memory management strategies
- Language runtime characteristics
