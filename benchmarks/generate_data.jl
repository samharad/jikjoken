#!/usr/bin/env julia
"""
Generate 1GB of test text for benchmarking.
Uses diverse text samples to simulate real-world tokenization workloads.
"""

using Random

function generate_test_corpus(output_file::String, target_gb::Float64=1.0)
    target_bytes = round(Int, target_gb * 1024^3)

    # Diverse text samples representing different content types
    samples = [
        # Code
        """
        function fibonacci(n)
            if n <= 1
                return n
            end
            return fibonacci(n-1) + fibonacci(n-2)
        end
        """,

        # Natural language
        """
        The quick brown fox jumps over the lazy dog. This sentence contains every letter of the alphabet.
        Machine learning models have revolutionized natural language processing in recent years.
        Artificial intelligence continues to advance at an unprecedented pace, enabling new applications.
        """,

        # Technical documentation
        """
        ## Installation

        To install this package, run:
        ```bash
        pip install example-package
        ```

        ### Requirements
        - Python 3.8 or higher
        - NumPy >= 1.20.0
        - PyTorch >= 1.9.0
        """,

        # JSON-like data
        """
        {
            "id": 12345,
            "name": "Example User",
            "email": "user@example.com",
            "roles": ["admin", "developer"],
            "active": true
        }
        """,

        # Conversation
        """
        User: How do I tokenize text efficiently?
        Assistant: There are several approaches to text tokenization. The most common methods include:
        1. Byte-Pair Encoding (BPE)
        2. WordPiece tokenization
        3. SentencePiece
        Each has its own trade-offs in terms of vocabulary size and efficiency.
        """,

        # Mixed content with special characters
        """
        Email: support@company.com | Phone: +1-555-0123
        Price: \$99.99 (20% off!) → New price: \$79.99
        Unicode: Hello 世界! Привет мир! مرحبا بالعالم
        Math: f(x) = ∫₀^∞ e^(-x²) dx = √π/2
        """,
    ]

    println("Generating $(target_gb)GB of test data...")
    println("Target: $(target_bytes) bytes")

    open(output_file, "w") do io
        bytes_written = 0
        iteration = 0

        while bytes_written < target_bytes
            # Randomly select and write samples
            sample = rand(samples)
            write(io, sample)
            bytes_written += sizeof(sample)

            # Add some newlines for variety
            write(io, "\n\n")
            bytes_written += 2

            iteration += 1
            if iteration % 10000 == 0
                progress = bytes_written / target_bytes * 100
                println("Progress: $(round(progress, digits=1))% ($(bytes_written ÷ 1024^2) MB)")
            end
        end

        println("\nGenerated $(bytes_written) bytes ($(round(bytes_written/1024^3, digits=2)) GB)")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    output_file = get(ARGS, 1, "test_data_1gb.txt")
    target_gb = length(ARGS) >= 2 ? parse(Float64, ARGS[2]) : 1.0

    println("Generating test corpus: $output_file")
    generate_test_corpus(output_file, target_gb)
    println("Done!")
end
