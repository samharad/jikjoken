# Performance Comparison: JikJoken vs tiktoken

## Benchmark Setup

- **Text corpus**: 512.00 MB (0.50 GB)
- **Tokenizer**: GPT-2
- **Number of runs**: 3

## Results

| Library | Language | Mean Time | Throughput | Relative Performance |
|---------|----------|-----------|------------|---------------------|
| **JikJoken** | Julia | 68.715s | **7.45 MB/s** | **0.83x faster** |
| tiktoken | Python | 56.891s | 9.00 MB/s | 1.00x (baseline) |

## Throughput Comparison

```
JikJoken (Julia)  █████████████████████████████████████ 7.45 MB/s
tiktoken (Python) ████████████████████████████████████████████ 9.00 MB/s
```

*Each █ represents ~0.2 MB/s*

## Detailed Statistics

### JikJoken (Julia)
- Mean time: 68.715s
- Min time: 68.186s
- Max time: 69.536s
- Throughput: 7.45 MB/s
- Tokens processed: 182,659,894

### tiktoken (Python)
- Mean time: 56.891s
- Min time: 56.698s
- Max time: 57.007s
- Throughput: 9.00 MB/s
- Tokens processed: 182,659,894

## Summary

JikJoken is **17.2% slower** than tiktoken when processing large text corpora.

Both libraries are built on the same Rust core (tiktoken_core), so the performance difference is primarily due to:
- FFI overhead differences between Julia ccall and Python ctypes/CFFI
- Memory management strategies
- Language runtime characteristics
