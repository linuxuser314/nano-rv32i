#!/bin/bash
# Stop script execution if any command fails
set -e

IS_RISCV_TEST=0
ASM_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -test) IS_RISCV_TEST=1 ;;
        *) ASM_FILE=$1 ;;
    esac
    shift
done

if [ -z "$ASM_FILE" ]; then
    echo "Usage: ./tools/build-sim.sh [-test] <input_asm.s>"
    echo "Example (Normal): ./tools/build-sim.sh sim/basic_instruction_test.s"
    echo "Example (Test)  : ./tools/build-sim.sh -test sim/rv32i-p/simple.S"
    exit 1
fi

# Toolchain prefix
TOOLCHAIN_PREFIX="riscv64-unknown-elf-"

# Define absolute path to your custom environment configuration
ENV_DIR="/workspaces/nano-rv32i/sim/custom_env"

echo "==> 1. Assembling $ASM_FILE..."
if [ $IS_RISCV_TEST -eq 1 ]; then
    echo "    (Using absolute paths for riscv-tests macros and linker)"
    
    # Verify the absolute directory path exists before compiling
    if [ ! -d "$ENV_DIR" ]; then
        echo "[ERROR] Custom environment directory not found at: $ENV_DIR"
        echo "Please make sure your link.ld and riscv_test.h are in that folder."
        exit 1
    fi

    # Using absolute directory tracking for include search paths (-I) and linker maps (-T)
    ${TOOLCHAIN_PREFIX}gcc -march=rv32i -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles \
        -I "$ENV_DIR/" \
        -T "$ENV_DIR/link.ld" \
        -o temp.elf "$ASM_FILE"
else
    echo "    (Using standard bare-metal build)"
    ${TOOLCHAIN_PREFIX}gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Wl,-Ttext=0x0 -o temp.elf "$ASM_FILE"
fi

echo "==> 2. Converting to 32-bit Verilog Hex format..."
${TOOLCHAIN_PREFIX}objcopy -O verilog --verilog-data-width=4 temp.elf temp.hex

echo "==> 3. Loading Hex file into Instruction ROM path..."
mkdir -p /workspaces/nano-rv32i/software/
cp temp.hex /workspaces/nano-rv32i/software/firmware.hex

# -------------------------------------------------------------------------
# 3. Compilation and Simulation
# -------------------------------------------------------------------------
echo "==> 4. Compiling RTL and Testbench using iverilog..."
# Hardwired output structure to compile the testbench cleanly
iverilog -g2012 -s datapath_tb -o sim.vvp /workspaces/nano-rv32i/sim/datapath_tb.sv /workspaces/nano-rv32i/rtl/*.sv

echo "==> 5. Running simulation..."
vvp sim.vvp -fst

# -------------------------------------------------------------------------
# 4. Waveform Extraction
# -------------------------------------------------------------------------
echo "==> 6. Processing waveform file..."

TARGET_WAVEFORM="/workspaces/nano-rv32i/sim/simulation.fst"

# Intercept the local file and move it to the absolute path for Surfer auto-refresh
if [ -f "simulation.fst" ]; then
    mkdir -p "$(dirname "$TARGET_WAVEFORM")"
    mv simulation.fst "$TARGET_WAVEFORM"
fi

if [ -f "$TARGET_WAVEFORM" ]; then
    echo "-------------------------------------------------------"
    echo "SUCCESS! Waveform safely saved to: $TARGET_WAVEFORM"
    echo "Refresh Surfer to view the new waveform!"
    echo "-------------------------------------------------------"
else
    echo "WARNING: 'simulation.fst' was not found!"
fi

# Clean up temporary compilation artifacts
rm -f temp.elf temp.hex sim.vvp