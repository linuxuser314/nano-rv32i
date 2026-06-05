#!/bin/bash
# Stop script execution if any command fails
set -e

# Validate arguments (Now strictly expecting .s and .fst)
if [ "$#" -ne 2 ]; then
    echo "Usage: ./tools/build-sim.sh <input_asm.s> <output_wave.fst>"
    echo "Example: ./tools/build-sim.sh sim/basic_instruction_test.s sim/basic_instruction_test.fst"
    exit 1
fi

ASM_FILE=$1
FST_FILE=$2

# Toolchain prefix (Adjust if your path uses riscv32-unknown-elf-)
TOOLCHAIN_PREFIX="riscv64-unknown-elf-"

# -------------------------------------------------------------------------
# 1. Assembly and Hex Generation
# -------------------------------------------------------------------------
echo "==> 1. Assembling $ASM_FILE..."
${TOOLCHAIN_PREFIX}gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Wl,-Ttext=0x0 -o temp.elf "$ASM_FILE"

echo "==> 2. Converting to 32-bit Verilog Hex format..."
# --verilog-data-width=4 stitches the bytes into 32-bit words for your ROM
${TOOLCHAIN_PREFIX}objcopy -O verilog --verilog-data-width=4 temp.elf temp.hex

# -------------------------------------------------------------------------
# 2. ROM Preparation
# -------------------------------------------------------------------------
echo "==> 3. Loading Hex file into Instruction ROM path..."
mkdir -p /workspaces/nano-rv32i/software/
cp temp.hex /workspaces/nano-rv32i/software/firmware.hex

# -------------------------------------------------------------------------
# 3. Compilation and Simulation
# -------------------------------------------------------------------------
echo "==> 4. Compiling RTL and Testbench using iverilog..."
# Using absolute paths so the script works when called from any directory.
# Note: Adjust the rtl/ path if it lives outside of /workspaces/nano-rv32i/
iverilog -g2012 -s datapath_tb -o sim.vvp /workspaces/nano-rv32i/sim/datapath_tb.sv /workspaces/nano-rv32i/rtl/*.sv

echo "==> 5. Running simulation..."
# Run simulation (the testbench $dumpfile should output simulation.fst)
vvp sim.vvp -fst

# -------------------------------------------------------------------------
# 4. Waveform Extraction
# -------------------------------------------------------------------------
echo "==> 6. Processing waveform file..."
if [ -f "simulation.fst" ]; then
    # Ensure the target directory for the FST file exists
    mkdir -p "$(dirname "$FST_FILE")"
    mv simulation.fst "$FST_FILE"
    
    echo "-------------------------------------------------------"
    echo "SUCCESS! Waveform saved to: $FST_FILE"
    echo "View it using: gtkwave $FST_FILE"
    echo "-------------------------------------------------------"
else
    echo "WARNING: 'simulation.fst' was not found!"
    echo "Make sure your testbench has these exact lines inside an initial block:"
    echo "  \$dumpfile(\"simulation.fst\");"
    echo "  \$dumpvars(0, datapath_tb);"
fi

# Clean up temporary artifacts
rm -f temp.elf temp.hex sim.vvp