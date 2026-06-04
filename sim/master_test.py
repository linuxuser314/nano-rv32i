#!/usr/bin/env python3
"""
################################################################################
# CREATOR CITATION: Created by Gemini (Google)
#
# DESCRIPTION: Master Verification Environment
# Scans for '*_test.py' plugin modules, presents a menu, and handles the
# full generation, compilation, simulation, and error logging pipeline.
################################################################################
"""

import os
import sys
import glob
import random
import subprocess
import datetime
import importlib.util

def main():
    print("=" * 60)
    print("--- Master SystemVerilog Verification Environment ---")
    print("=" * 60)
    
    # 1. Scan for test plugins
    test_files = glob.glob("*_test.py")
    test_files = [f for f in test_files if f != "master_test.py"]
    
    if not test_files:
        print("\n[ERROR] No test modules (*_test.py) found in the current directory.")
        print("Please create a module_name_test.py plugin to proceed.")
        return

    # 2. Menu Selection
    print("\nAvailable Test Modules:")
    modules = []
    for i, f in enumerate(test_files):
        mod_name = f.replace("_test.py", "")
        modules.append((mod_name, f))
        print(f"  {i + 1}) {mod_name}")
    
    try:
        choice = int(input(f"\nSelect module to test (1-{len(modules)}): ")) - 1
        if choice < 0 or choice >= len(modules):
            raise ValueError
    except ValueError:
        print("Invalid choice. Exiting.")
        return

    selected_module_name, selected_file = modules[choice]
    
    # 3. Dynamically Load the Plugin
    spec = importlib.util.spec_from_file_location(selected_module_name, selected_file)
    test_plugin = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(test_plugin)
    
    rtl_module = getattr(test_plugin, "MODULE_NAME", selected_module_name)
    
    # 4. Check for RTL file
    sv_file = f"../rtl/{rtl_module}.sv"
    if not os.path.exists(sv_file):
        print(f"\n[WARNING] '{sv_file}' not found.")
        print(f"Please ensure your RTL file is located at '{sv_file}'.")
        input("Press Enter once the file is available, or Ctrl+C to abort...")

    # 5. Iterations Input
    try:
        num_iterations = int(input("\nHow many test iterations would you like to run? "))
    except ValueError:
        print("Invalid input. Defaulting to 1000 iterations.")
        num_iterations = 1000

    # 6. Global RNG Seed
    seed = random.randrange(sys.maxsize)
    random.seed(seed)
    print(f"\n[INFO] Random Seed generated: {seed}")
    
    # 7. Generate Vectors via Plugin
    print(f"[INFO] Generating {num_iterations} test vectors (Edge & Random Mixed)...")
    tv_file = f"{rtl_module}_vectors.tv"
    vectors = test_plugin.generate_vectors(num_iterations)
    
    with open(tv_file, 'w') as f:
        for v in vectors:
            f.write(v + '\n')
            
    print(f"[INFO] Writing vectors to {tv_file}")
    
    # 8. Generate Testbench via Plugin
    tb_file = f"{rtl_module}_tb.sv"
    print(f"[INFO] Generating testbench {tb_file}...")
    tb_code = test_plugin.get_testbench_code(num_iterations, tv_file)
    with open(tb_file, 'w') as f:
        f.write(tb_code)

    # 9. Compile and Simulate
    sim_out = f"{rtl_module}_sim.out"
    print("\n[INFO] Compiling via iverilog...")
    compile_cmd = ["iverilog", "-g2012", "-y", "../rtl", "-Y", ".sv", sv_file, tb_file, "-o", sim_out]
    compile_result = subprocess.run(compile_cmd, capture_output=True, text=True)

    if compile_result.returncode != 0:
        print("\n[CRITICAL ERROR] Compilation failed!")
        print(compile_result.stderr)
        sys.exit(1)

    print("[INFO] Simulating via vvp...")
    sim_cmd = ["vvp", sim_out]
    sim_result = subprocess.run(sim_cmd, capture_output=True, text=True)

    # 10. Parse Output
    output_lines = sim_result.stdout.split('\n')
    errors = [line for line in output_lines if line.startswith("ERROR")]
    total_errors_line = next((line for line in output_lines if "Total Errors" in line), None)
    
    if total_errors_line:
        print(f"\n[SIMULATION RESULT] {total_errors_line}")
    else:
        print("\n[SIMULATION ERROR] Could not find completion message. Simulation may have crashed.")
        print(sim_result.stdout)

    # 11. Error Logging
    err_log = f"{rtl_module}_errors.log"
    if errors:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(err_log, 'w') as f:
            f.write(f"--- Error Log for {rtl_module} ---\n")
            f.write(f"Date/Time: {timestamp}\n")
            f.write(f"RNG Seed : {seed}\n")
            f.write(f"-------------------------------------\n")
            for err in errors:
                f.write(err + '\n')
        
        print(f"[WARNING] {len(errors)} mismatches detected. Details saved to {err_log}.")
        view_err = input("Would you like to view the errors in the console now? (y/n): ")
        if view_err.lower() == 'y':
            print("-" * 50)
            for err in errors[:50]:
                print(err)
            if len(errors) > 50:
                print(f"... and {len(errors) - 50} more. (See {err_log})")
            print("-" * 50)
    else:
        print("[SUCCESS] All test vectors passed successfully!")

    # 12. Cleanup
    print("\n[INFO] Cleaning up temporary test files...")
    for temp_file in [tv_file, tb_file, sim_out]:
        if os.path.exists(temp_file):
            os.remove(temp_file)
            print(f"       -> Removed {temp_file}")

if __name__ == "__main__":
    main()