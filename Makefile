# --- Directories & Configuration ---
NANO_ROOT ?= $(CURDIR)
BUILD_DIR = $(NANO_ROOT)/build
LOGS_DIR = $(NANO_ROOT)/logs
TARGET_DIR ?= $(BUILD_DIR)/target

# --- Toolchain ---
GCC = riscv64-unknown-elf-gcc
LD = riscv64-unknown-elf-ld
OBJDUMP = riscv64-unknown-elf-objdump
OBJCOPY = riscv64-unknown-elf-objcopy

# --- Build-ASM Variables ---
SRC ?= software/blinky.s
BASENAME = $(basename $(notdir $(SRC)))
OBJ_FILE = $(BUILD_DIR)/artifacts/$(BASENAME).o
ELF_FILE = $(BUILD_DIR)/artifacts/$(BASENAME).elf
DUMP_FILE = $(LOGS_DIR)/$(BASENAME).dump
TEXT_HEX = $(TARGET_DIR)/boot_rom.hex
DATA_HEX = $(TARGET_DIR)/system_ram.hex

# Compiler Flags (Defaults)
AS_FLAGS = -march=rv32i -mabi=ilp32 -c
LD_FLAGS = -m elf32lriscv

# Automatic riscv-tests detection
ifneq (,$(findstring riscv-tests,$(SRC)))
	TEST_ENV = sim/vendor/riscv-tests/custom_env
	TEST_MACROS = sim/vendor/riscv-tests/isa/macros/scalar
	AS_FLAGS += -I$(TEST_ENV) -I$(TEST_MACROS)
	LD_FLAGS += -T $(TEST_ENV)/link.ld
else
	LD_FLAGS += -Ttext 0x00000000
endif

# --- Python Hex Formatter (Inline) ---
define FORMAT_HEX_PY
import sys, os
def format_hex(src, dst):
	if not os.path.exists(src) or os.path.getsize(src) == 0:
		with open(dst, 'w') as f: f.write('@00000000\n00000000\n')
		return
	with open(src, 'r') as f: data = f.read().split()
	bytes_only = [b for b in data if not b.startswith('@')]
	words = []
	for i in range(0, len(bytes_only), 4):
		if i+3 < len(bytes_only):
			words.append(bytes_only[i+3] + bytes_only[i+2] + bytes_only[i+1] + bytes_only[i])
	with open(dst, 'w') as f: f.write('@00000000\n' + '\n'.join(words) + '\n')
format_hex(sys.argv[1], sys.argv[2])
endef
export FORMAT_HEX_PY

.PHONY: all build-asm build-sim run-sim build-synth clean test-toolchain run-tests

# --- TARGETS ---

# --- TARGETS ---
# (Keep your existing variable definitions at the top)

# 1. Build Assembly into Hex
build-asm:
	@mkdir -p $(BUILD_DIR)/artifacts $(LOGS_DIR) $(TARGET_DIR)
	@echo "Assembler: Compiling $(BASENAME)..."
	@$(GCC) $(AS_FLAGS) $(SRC) -o $(OBJ_FILE)
	@$(LD) $(LD_FLAGS) $(OBJ_FILE) -o $(ELF_FILE)
	@$(OBJDUMP) -d $(ELF_FILE) > $(DUMP_FILE)
	@$(OBJCOPY) -j .text -O verilog $(ELF_FILE) $(BUILD_DIR)/artifacts/$(BASENAME).text.hex
	@$(OBJCOPY) -j .data -j .sdata -j .rodata -O verilog $(ELF_FILE) $(BUILD_DIR)/artifacts/$(BASENAME).data.hex
	@python3 -c "$$FORMAT_HEX_PY" $(BUILD_DIR)/artifacts/$(BASENAME).text.hex $(TARGET_DIR)/text.hex
	@python3 -c "$$FORMAT_HEX_PY" $(BUILD_DIR)/artifacts/$(BASENAME).data.hex $(TARGET_DIR)/data.hex

# 2. Run Cocotb Simulation (Builds Verilator & Runs Testbench in 1 step)
run-sim:
	@mkdir -p $(BUILD_DIR)/sim $(LOGS_DIR)
	@echo "Cocotb: Building and Running Simulation..."
	@python3 sim/test_soc.py > $(LOGS_DIR)/sim-output.txt 2>&1
	@if [ -f "dump.fst" ]; then mv dump.fst $(LOGS_DIR)/sim_trace.fst; fi
	@echo "Simulation Complete. See logs/sim-output.txt"

# (Keep run-tests, build-synth, clean, etc. below)

# 4. Run Test Suite
run-tests:
	@python3 tools/run_tests.py

# 5. Build Synthesis (Tang Nano 20K)
build-synth:
	@mkdir -p $(BUILD_DIR) $(LOGS_DIR)
	@echo "Synthesis (1/4): Transpiling with sv2v..."
	@sv2v $$(grep -v '^[#+]' filelist.f) > $(BUILD_DIR)/flattened.v
	@echo "Synthesis (2/4): Yosys logic synthesis..."
	@yosys -e ".*latch.*" -p "read_verilog $(BUILD_DIR)/flattened.v; synth_gowin -top soc_top -json $(BUILD_DIR)/core.json" > $(LOGS_DIR)/yosys.log 2>&1
	@echo "Synthesis (3/4): NextPNR Place and Route..."
	@nextpnr-himbaechel --json $(BUILD_DIR)/core.json --write $(BUILD_DIR)/routed.json --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=nano20k.cst --report $(LOGS_DIR)/timing_report.json > $(LOGS_DIR)/nextpnr.log 2>&1
	@echo "Synthesis (4/4): Bitstream generation..."
	@gowin_pack -d GW2A-18C -o firmware.fs $(BUILD_DIR)/routed.json > $(LOGS_DIR)/gowin.log 2>&1
	@echo "======================================"
	@echo "          SYNTHESIS COMPLETE          "
	@echo "======================================"
	@grep -A 10 "Info: Device utilisation:" $(LOGS_DIR)/nextpnr.log
	@grep "Max frequency" $(LOGS_DIR)/nextpnr.log || true

# 6. Clean Workspace (Interactive)
clean:
	git clean -Xdi

# 7. CI/CD Toolchain Test (Non-Interactive)
test-toolchain:
	@echo "--- Starting CI/CD Toolchain Test ---"
	git clean -Xdf
	make build-sim
	make build-asm SRC=software/blinky.s TARGET_DIR=software
	make run-sim
	@echo "--- Toolchain Verification Passed! ---"