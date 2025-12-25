#!/bin/bash
# Copyright (c) 2021 ETH Zurich, University of Bologna
#
# Copyright and related rights are licensed under the Solderpad Hardware
# License, Version 0.51 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Authors:
# - Fabian Schuiki <fschuiki@iis.ee.ethz.ch>
# - Florian Zaruba <zarubaf@iis.ee.ethz.ch>
# - Andreas Kurth <akurth@iis.ee.ethz.ch>

set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if [ -z "${VERILATOR:-}" ]; then
    VERILATOR=verilator
fi

# Default mode is lint-only
MODE="lint"
TEST_MODULE=""

# Parse arguments
PARAMS=()
while (( "$#" )); do
    case "$1" in
        --lint-only)
            MODE="lint"
            shift;;
        --test)
            MODE="test"
            if [ $# -lt 2 ]; then
                echo "Error: --test requires a test module name" >&2
                exit 1
            fi
            # Validate test module name immediately to prevent command injection
            if [[ ! "$2" =~ ^[a-zA-Z0-9_]+$ ]]; then
                echo "Error: Invalid test module name '$2'. Only alphanumeric characters and underscores are allowed." >&2
                exit 1
            fi
            TEST_MODULE="$2"
            shift 2;;
        -*|--*) # unsupported flag
            echo "Error: Unsupported flag '$1'." >&2
            exit 1;;
        *) # preserve positional arguments
            PARAMS+=("$1")
            shift;;
    esac
done
# Restore positional parameters
set -- "${PARAMS[@]}"

# Common Verilator flags
VERILATOR_FLAGS=()
VERILATOR_FLAGS+=(-Wno-fatal)
VERILATOR_FLAGS+=(-sv)

if [ "$MODE" = "lint" ]; then
    # Lint mode for synthesis bench
    echo "Running Verilator in lint-only mode on axi_synth_bench..."
    bender script verilator -t synthesis -t synth_test > ./verilator.f
    $VERILATOR --top-module axi_synth_bench --lint-only -f verilator.f ${VERILATOR_FLAGS[@]}
    echo "Verilator lint check completed successfully."
elif [ "$MODE" = "test" ]; then
    # Test mode - lint specific testbench
    if [ ! -e "$ROOT/test/tb_$TEST_MODULE.sv" ]; then
        echo "Error: Testbench for '$TEST_MODULE' not found!"
        exit 1
    fi
    echo "Running Verilator lint check on tb_$TEST_MODULE..."
    bender script verilator -t test -t rtl > ./verilator.f
    $VERILATOR --top-module tb_$TEST_MODULE --lint-only -f verilator.f ${VERILATOR_FLAGS[@]}
    echo "Verilator lint check for tb_$TEST_MODULE completed successfully."
else
    echo "Error: Unknown mode '$MODE'"
    exit 1
fi
