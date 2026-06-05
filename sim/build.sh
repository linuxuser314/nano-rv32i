#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Compile assembly to object file
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c -nostdlib -o firmware.o firmware.s

# Extract raw binary
riscv64-unknown-elf-objcopy -O binary firmware.o firmware.bin

# Turn raw binary into Verilog-readable Hex
od -An -v -tx4 -w4 firmware.bin | awk '{print $1}' > ../rtl/firmware.hex

echo "Successfully built firmware.hex and updated the RTL directory!"
