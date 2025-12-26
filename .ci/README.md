# Verilator-based CI Test Environment

This directory contains the Dockerfile and configuration for building a Verilator-based CI test environment for the AXI repository.

## Quick Start

Build and test locally with Docker:
```bash
# Build the Docker image
docker build -t axi-verilator:latest -f .ci/Dockerfile.verilator .

# Run lint check on synthesis bench
docker run --rm -v $(pwd):/workspace -w /workspace/build \
    axi-verilator:latest \
    bash -c "mkdir -p /workspace/build && cd /workspace/build && ../scripts/run_verilator.sh --lint-only"
```

Or use the Makefile (requires local Verilator and Bender installation):
```bash
make verilator_lint_synth
```

## Overview

The Verilator test environment provides an open-source alternative to the existing QuestaSim/Modelsim-based test infrastructure. While the full simulation capabilities are being developed, the current implementation supports:

- Lint checking of the synthesis bench (`axi_synth_bench`)
- Lint checking of all individual testbenches
- Docker-based CI environment for reproducible testing

## Docker Image

### Building the Image

The Docker image includes:
- Verilator built from source (version 5.028)
- Rust toolchain and Cargo (from Ubuntu packages)
- Bender (hardware dependency manager)
- All necessary build dependencies

To build the Docker image locally:

```bash
docker build -t axi-verilator:latest -f .ci/Dockerfile.verilator .
```

**Note for SSL Inspection Environments**: If you're building behind a corporate proxy with SSL inspection, the Dockerfile is configured to handle self-signed certificates. However, cargo may still have issues accessing crates.io. In such environments, you may need to:
1. Configure your corporate proxy settings in Docker
2. Add trusted certificates to the container
3. Use a pre-built image from a trusted registry

### Using the Image

Run Verilator lint check on the synthesis bench:

```bash
docker run --rm -v $(pwd):/workspace -w /workspace/build \
    axi-verilator:latest \
    bash -c "mkdir -p /workspace/build && cd /workspace/build && ../scripts/run_verilator.sh --lint-only"
```

Run Verilator lint check on a specific testbench:

```bash
docker run --rm -v $(pwd):/workspace -w /workspace/build \
    axi-verilator:latest \
    bash -c "mkdir -p /workspace/build && cd /workspace/build && ../scripts/run_verilator.sh --test axi_xbar"
```

## Scripts

### compile_verilator.sh

Generates the file list for Verilator using Bender with the appropriate targets.

### run_verilator.sh

Main script for running Verilator checks. Supports:
- `--lint-only`: Lint check on synthesis bench (default)
- `--test <module>`: Lint check on a specific testbench

## Makefile Targets

The Makefile has been extended with Verilator support:

- `make verilator_lint_synth`: Run Verilator lint on synthesis bench
- `make verilator-<test>.vlt`: Run Verilator lint on specific testbench
- `make verilator_lint_all`: Run Verilator lint on all testbenches

Example:
```bash
make verilator_lint_synth
make verilator-axi_xbar.vlt
make verilator_lint_all
```

## GitHub Actions Workflow

The `.github/workflows/verilator-ci.yml` workflow runs:

1. **build-verilator-image**: Builds the Docker image with caching
2. **verilator-lint-synth**: Lints the synthesis bench
3. **verilator-lint-tests**: Lints all testbenches in parallel (matrix job)

The workflow is triggered on:
- Push to any branch (except gh-pages and version tags)
- Pull requests
- Manual workflow dispatch

## Current Limitations

The current implementation focuses on lint checking. The testbenches use SystemVerilog features that are not fully supported by Verilator for simulation:

- **Class-based testbenches**: The existing testbenches use SystemVerilog classes (e.g., `axi_rand_master_t`, `axi_rand_slave_t`) which Verilator doesn't support for simulation
- **Dynamic memory constructs**: Features like `push_back()`, `pop_front()` on queues, and other dynamic data structures
- **Randomization**: The `randomize()` construct and random class instances

These limitations are expected and the lint-only mode serves as a valuable first step for:
- Catching syntax errors
- Detecting basic type mismatches
- Identifying missing signals and connections
- Validating module instantiation correctness

## Verilator Version Note

The Docker image builds Verilator v5.028 from source to ensure the latest features and bug fixes. Some known issues in earlier versions (like v5.020 available in Ubuntu 22.04 repositories) include internal compiler errors on certain SystemVerilog constructs. Using a source-built version provides better compatibility.

## Future Work

- [ ] Add C++ testbench wrappers for full Verilator simulation
- [ ] Implement DPI-C interfaces for verification components
- [ ] Create simplified test cases specifically for Verilator
- [ ] Add code coverage collection with Verilator
- [ ] Integrate with existing CI infrastructure
