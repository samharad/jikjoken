#!/bin/bash
# Run complete benchmark suite comparing JikJoken vs tiktoken

set -e

BENCHMARK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BENCHMARK_DIR"

# Configuration
DATA_SIZE_GB=1.0
NUM_RUNS=3
DATA_FILE="test_data_${DATA_SIZE_GB}gb.txt"

echo "========================================================================"
echo "JikJoken vs tiktoken Performance Benchmark"
echo "========================================================================"
echo "Data size: ${DATA_SIZE_GB} GB"
echo "Number of runs: ${NUM_RUNS}"
echo ""

# Step 1: Generate test data if it doesn't exist
if [ ! -f "$DATA_FILE" ]; then
    echo "Step 1: Generating test data..."
    julia generate_data.jl "$DATA_FILE" "$DATA_SIZE_GB"
    echo ""
else
    echo "Step 1: Using existing test data: $DATA_FILE"
    echo ""
fi

# Step 2: Run JikJoken benchmark
echo "Step 2: Benchmarking JikJoken (Julia)..."
echo "------------------------------------------------------------------------"
julia --project=.. bench_jikjoken.jl "$DATA_FILE" "results_jikjoken.json" "$NUM_RUNS"
echo ""

# Step 3: Install tiktoken if needed and run benchmark
echo "Step 3: Benchmarking tiktoken (Python)..."
echo "------------------------------------------------------------------------"
if ! python3 -c "import tiktoken" 2>/dev/null; then
    echo "Installing tiktoken..."
    pip install -q tiktoken
fi
python3 bench_tiktoken.py "$DATA_FILE" "results_tiktoken.json" "$NUM_RUNS"
echo ""

# Step 4: Create visualization
echo "Step 4: Creating visualization..."
echo "------------------------------------------------------------------------"
python3 visualize.py results_jikjoken.json results_tiktoken.json performance_comparison.md
echo ""

echo "========================================================================"
echo "Benchmark complete!"
echo "========================================================================"
echo "Results saved to:"
echo "  - results_jikjoken.json"
echo "  - results_tiktoken.json"
echo "  - performance_comparison.md"
echo ""
echo "View the comparison:"
echo "  cat performance_comparison.md"
echo "========================================================================"
