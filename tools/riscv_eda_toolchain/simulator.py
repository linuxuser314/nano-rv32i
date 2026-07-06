# tools/riscv_eda_toolchain/simulator.py

import os
import sys
import subprocess
import shutil
from .io_utils import get_nano_root, is_stale

def compile_hdl(rtl_files, wrapper_cpp, top_module="soc_top"):
    """
    Verilates and compiles the SystemVerilog design into a high-performance 
    C++ executable simulation binary. Skips compilation if up to date.
    
    rtl_files: List of absolute paths to the SV files (from get_rtl_files()).
    wrapper_cpp: Absolute path to the C++ testbench wrapper (e.g., Vsoc_top.cpp).
    top_module: The name of your top-level SystemVerilog module.
    """
    nano_root = get_nano_root()
    build_dir = os.path.join(nano_root, "build")
    obj_dir = os.path.join(build_dir, "obj_dir")
    
    # The final target binary executable that Verilator produces
    target_bin = os.path.join(obj_dir, f"V{top_module}")

    # Combine all dependencies: Every single RTL file + the C++ testbench wrapper
    dependencies = rtl_files + [wrapper_cpp]

    # Use our io_utils tracker! If nothing changed, exit early.
    if not is_stale(dependencies, target_bin):
        print(f"⏩ [PASS][0.0][VRIBLE] Simulator binary is up to date: V{top_module}")
        return True

    print(f"🛠️  [****][0.0][VRIBLE] Rebuilding hardware model (Running Verilator)...")
    
    # Ensure the build directory exists
    os.makedirs(build_dir, exist_ok=True)

    # Step 1: Run Verilator to convert SV to C++ code
    # We pass --cc (C++ mode), --exe (build executable), --trace (for VCD waveforms)
    # and -Mdir to force outputs into build/obj_dir
    verilator_cmd = [
        "verilator",
        "--cc",
        "--exe",
        "--trace",
        "-Wall",
        "-Mdir", obj_dir,
        "--top-module", top_module,
        "-I" + os.path.join(nano_root, "rtl"),
        wrapper_cpp
    ] + rtl_files

    # Execute Verilator stage
    res_verilator = subprocess.run(verilator_cmd, capture_output=True, text=True)
    if res_verilator.returncode != 0:
        print(f"❌ [FAIL][0.0][VRIBLE] Verilator translation failed!\n")
        print(res_verilator.stderr)
        return False

    # Step 2: Compile the generated C++ code into the final binary executable
    # Verilator generates a custom Makefile tailored to your top module inside obj_dir
    make_cmd = [
        "make",
        "-C", obj_dir,
        "-f", f"V{top_module}.mk"
    ]

    print(f"🛠️  [****][0.0][VRIBLE] Compiling C++ model binaries...")
    res_make = subprocess.run(make_cmd, capture_output=True, text=True)
    if res_make.returncode != 0:
        print(f"❌ [FAIL][0.0][VRIBLE] C++ compilation failed!\n")
        print(res_make.stderr)
        return False

    print(f"✅ [PASS][0.0][VRIBLE] Simulator compiled successfully: {target_bin}")
    # ... inside compile_hdl after the make command succeeds ...
    generated_bin = os.path.join(obj_dir, f"V{top_module}")
    final_bin = os.path.join(build_dir, "soc_executable")

    print(f"📦 Moving and renaming simulation binary to {final_bin}...")
    shutil.copy2(generated_bin, final_bin) # copy2 preserves file permissions (executable bits)
    return True