# tools/riscv_eda_toolchain/simulator.py

import os
import subprocess
import shutil
from .io_utils import get_nano_root, is_stale, ToolchainResult

def compile_hdl(rtl_files, wrapper_cpp, top_module="soc_top") -> ToolchainResult:
    nano_root = get_nano_root()
    build_dir = os.path.join(nano_root, "build")
    obj_dir = os.path.join(build_dir, "obj_dir")
    
    target_bin = os.path.join(obj_dir, f"V{top_module}")
    final_bin = os.path.join(build_dir, "soc_executable")
    
    dependencies = rtl_files + [wrapper_cpp]

    if not is_stale(dependencies, target_bin):
        return ToolchainResult(True, "VRIBLE", "Simulator binary up to date.", {"sim_bin": final_bin})

    os.makedirs(build_dir, exist_ok=True)

    verilator_cmd = [
        "verilator", "--cc", "--exe", "--trace-fst", "-Wall", "-Wno-fatal",
        "-O3", "--x-assign", "fast", "--x-initial", "fast",
        "-Mdir", obj_dir, "--top-module", top_module,
        "-I" + os.path.join(nano_root, "rtl"), wrapper_cpp
    ] + rtl_files

    res_verilator = subprocess.run(verilator_cmd, capture_output=True, text=True)
    if res_verilator.returncode != 0:
        return ToolchainResult(False, "VRIBLE", f"Verilator translation failed:\n{res_verilator.stderr}")

    make_cmd = ["make", "-C", obj_dir, "-j", str(os.cpu_count() or 2), "-f", f"V{top_module}.mk"]
    res_make = subprocess.run(make_cmd, capture_output=True, text=True)
    
    if res_make.returncode != 0:
        return ToolchainResult(False, "MAKE", f"C++ compilation failed:\n{res_make.stderr}")

    shutil.copy2(target_bin, final_bin)
    
    return ToolchainResult(True, "VRIBLE", "Simulator compiled successfully.", {"sim_bin": final_bin})