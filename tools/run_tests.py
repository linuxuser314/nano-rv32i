#!/usr/bin/env python3
import os
import glob
import subprocess
import sys

NANO_ROOT = os.environ.get("NANO_ROOT", ".")
TEST_DIR = os.path.join(NANO_ROOT, "sim/vendor/riscv-tests/rv32i-p-asm")

def main():
    print("=" * 50 + "\n🚀 NANO-RV32I AUTOMATED TEST SUITE\n" + "=" * 50)

    # 1. Compile Simulator
    print("\n[1/3] Compiling Verilator Model...")
    res = subprocess.run(["make", "build-sim"], capture_output=True, text=True)
    if res.returncode != 0:
        print("❌ ERROR: Simulator failed to build!\n" + res.stderr)
        sys.exit(1)

    # 2. Find Tests
    test_files = sorted(glob.glob(os.path.join(TEST_DIR, "*.S")))
    print(f"[2/3] Found {len(test_files)} tests. Running suite...\n")

    passed = failed = crashed = 0

    # 3. Testing Loop
    for test in test_files:
        test_name = os.path.basename(test).replace('.S', '')

        # A. Assemble test and place directly into the software/ folder for soc_top.sv
        asm_res = subprocess.run(["make", "build-asm", f"SRC={test}", "TARGET_DIR=build/target"], capture_output=True, text=True)
        if asm_res.returncode != 0:
            print(f"[{test_name.ljust(15)}] ❌ ASM BUILD FAILED")
            crashed += 1
            continue

        # B. Run Simulation
        subprocess.run(["make", "run-sim"], capture_output=True)

        # C. Parse Log
        try:
            with open("logs/sim-output.txt", "r") as f:
                output = f.read()
            
            faults = [line.strip() for line in output.split('\n') if "HARDWARE FAULT:" in line]

            if "RISC-V TEST PASSED!" in output:
                print(f"[{test_name.ljust(15)}] ✅ PASSED")
                passed += 1
            elif "RISC-V TEST FAILED!" in output:
                failed += 1
                for line in output.split('\n'):
                    if "FAILED!" in line:
                        print(f"[{test_name.ljust(15)}] ❌ {line.strip()}")
            else:
                crashed += 1
                if faults:
                    print(f"[{test_name.ljust(15)}] 💥 CRASHED ({faults[0]})")
                else:
                    print(f"[{test_name.ljust(15)}] ⚠️ TIMEOUT / NO OUTPUT")
        except FileNotFoundError:
            print(f"[{test_name.ljust(15)}] 💥 CRASHED (No log output)")
            crashed += 1

    print("\n" + "=" * 50 + "\n🏆 FINAL SCOREBOARD\n" + "=" * 50)
    print(f"✅ PASSED : {passed}\n❌ FAILED : {failed}\n⚠️ CRASHED: {crashed}")

if __name__ == "__main__":
    main()