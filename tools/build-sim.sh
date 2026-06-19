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
    echo "Example (Test)  : ./tools/build-sim.sh -test sim/riscv-tests/isa/rv32ui/add.S"
    exit 1
fi

# Toolchain prefix
TOOLCHAIN_PREFIX="riscv64-unknown-elf-"

echo "==> 1. Assembling $ASM_FILE..."
if [ $IS_RISCV_TEST -eq 1 ]; then
    echo "    (Using custom riscv-tests macros and linker)"
    # We include our custom macro folder and explicitly use our custom linker script
    ${TOOLCHAIN_PREFIX}gcc -march=rv32i -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles \
        -I sim/custom_env/ \
        -T sim/custom_env/link.ld \
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

echo "==> 4. Compiling RTL and Testbench using iverilog..."
iverilog -g2012 -s datapath_tb -o sim.vvp /workspaces/nano-rv32i/sim/datapath_tb.sv /workspaces/nano-rv32i/rtl/*.sv

echo "==> 5. Running simulation..."
vvp sim.vvp -fst

echo "==> 6. Processing waveform file..."
if [ -f "simulation.fst" ]; then
    echo "-------------------------------------------------------"
    echo "SUCCESS! Waveform generated at: simulation.fst"
    echo "View it using: gtkwave simulation.fst"
    echo "-------------------------------------------------------"
else
    echo "WARNING: 'simulation.fst' was not found!"
fi

# Clean up temporary artifacts
rm -f temp.elf temp.hex sim.vvp