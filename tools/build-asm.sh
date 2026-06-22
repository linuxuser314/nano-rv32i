#!/bin/bash

# Exit immediately if any command fails
set -e

# --- 1. ARGUMENT PARSING ---
if [ -z "$1" ]; then
    echo "Usage: build-asm.sh <path/to/file.s> [--riscv-test]"
    exit 1
fi

SRC_FILE="$1"
DIR=$(dirname "$SRC_FILE")
# Extract the filename without the .s or .S extension
BASENAME=$(basename "$SRC_FILE" | sed 's/\.[sS]$//')

OBJ_FILE="$DIR/$BASENAME.o"
ELF_FILE="$DIR/$BASENAME.elf"
HEX_FILE="$DIR/$BASENAME.hex"
DUMP_FILE="$DIR/$BASENAME.dump"

# --- 2. ENVIRONMENT SETUP ---
# Default to standard simple assembly
AS_FLAGS="-march=rv32i -mabi=ilp32 -c"
LD_FLAGS="-m elf32lriscv -Ttext 0x00000000"

if [[ "$2" == "-riscv-test" || "$2" == "--riscv-test" ]]; then
    echo "🧪 RISC-V Test Environment Detected"
    TEST_ENV="/workspaces/nano-rv32i/sim/vendor/riscv-tests/custom_env"
    TEST_MACROS="/workspaces/nano-rv32i/sim/vendor/riscv-tests/isa/macros/scalar"
    
    # Add include paths for the test macros
    AS_FLAGS="-march=rv32i -mabi=ilp32 -I$TEST_ENV -I$TEST_MACROS -c"
    # Use the test framework's linker script
    LD_FLAGS="-m elf32lriscv -T $TEST_ENV/link.ld"
fi

# --- 3. BUILD PIPELINE ---
echo "🛠️  Assembling $SRC_FILE..."
riscv64-unknown-elf-gcc $AS_FLAGS "$SRC_FILE" -o "$OBJ_FILE"

echo "🔗 Linking..."
riscv64-unknown-elf-ld $LD_FLAGS "$OBJ_FILE" -o "$ELF_FILE"

echo "📝 Generating disassembly dump..."
riscv64-unknown-elf-objdump -d "$ELF_FILE" > "$DUMP_FILE"

echo "📦 Generating Verilog hex file..."
riscv64-unknown-elf-objcopy -O verilog "$ELF_FILE" "$HEX_FILE"

echo "🔧 Formatting hex into 32-bit words..."
python3 -c "
import sys
with open('$HEX_FILE', 'r') as f:
    data = f.read().split()
bytes_only = [b for b in data if not b.startswith('@')]
words = []
for i in range(0, len(bytes_only), 4):
    if i+3 < len(bytes_only):
        words.append(bytes_only[i+3] + bytes_only[i+2] + bytes_only[i+1] + bytes_only[i])
with open('$HEX_FILE', 'w') as f:
    f.write('@00000000\n' + '\n'.join(words) + '\n')
"

# --- 4. CLEANUP ---
echo "🧹 Cleaning up intermediate files..."
rm -f "$OBJ_FILE" "$ELF_FILE"

echo "✅ Done! Created $HEX_FILE and $DUMP_FILE"