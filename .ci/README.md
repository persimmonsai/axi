# Verilator-based CI Test Environment

This directory contains the Dockerfile and configuration for building a Verilator-based CI test environment for the AXI repository.

## Overview

The Verilator test environment provides an open-source alternative to the existing QuestaSim/Modelsim-based test infrastructure. While the full simulation capabilities are being developed, the current implementation supports:

- Lint checking of the synthesis bench (`axi_synth_bench`)
- Lint checking of all individual testbenches
- Docker-based CI environment for reproducible testing

## Docker Image

### Building the Image

The Docker image includes:
- Verilator built from source (version 5.028)
- Rust toolchain
- Bender (hardware dependency manager)
- All necessary build dependencies

To build the Docker image locally:

```bash
docker build -t axi-verilator:latest -f .ci/Dockerfile.verilator .
```

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

The current implementation focuses on lint checking. Full simulation support with Verilator requires:
- C++ testbench wrappers (testbenches currently use SystemVerilog classes and constructs not fully supported by Verilator)
- DPI-C interfaces for some verification components
- Potentially simplified testbenches for Verilator compatibility

These enhancements can be added incrementally as the Verilator environment matures.

## Future Work

- [ ] Add C++ testbench wrappers for full Verilator simulation
- [ ] Implement DPI-C interfaces for verification components
- [ ] Create simplified test cases specifically for Verilator
- [ ] Add code coverage collection with Verilator
- [ ] Integrate with existing CI infrastructure
