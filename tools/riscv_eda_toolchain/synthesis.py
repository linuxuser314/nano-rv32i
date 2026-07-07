# tools/riscv_eda_toolchain/synthesis.py

import os
import subprocess
from .io_utils import get_nano_root, get_rtl_files, is_stale, ToolchainResult

def synthesize(top_module="soc_top", device="GW2AR-LV18QN88C8/I7", family="GW2A-18C") -> ToolchainResult:
    nano_root = get_nano_root()
    build_dir = os.path.join(nano_root, "build")
    logs_dir = os.path.join(nano_root, "logs")
    
    os.makedirs(build_dir, exist_ok=True)
    os.makedirs(logs_dir, exist_ok=True)

    rtl_files = get_rtl_files()
    
    # Target artifacts
    flattened_v = os.path.join(build_dir, "flattened.v")
    core_json = os.path.join(build_dir, "core.json")
    routed_json = os.path.join(build_dir, "routed.json")
    firmware_fs = os.path.join(nano_root, "firmware.fs")
    cst_file = os.path.join(nano_root, "nano20k.cst")
    
    artifacts = {
        "flattened": flattened_v,
        "core_json": core_json,
        "routed_json": routed_json,
        "firmware": firmware_fs
    }

    if not is_stale(rtl_files + [cst_file], firmware_fs):
        return ToolchainResult(True, "SYNTH", "Firmware is up to date.", artifacts)

    # 1. SV2V Transpilation
    res_sv2v = subprocess.run(["sv2v"] + rtl_files, capture_output=True, text=True)
    if res_sv2v.returncode != 0:
        return ToolchainResult(False, "SV2V", f"Transpilation failed:\n{res_sv2v.stderr}")
    with open(flattened_v, "w") as f:
        f.write(res_sv2v.stdout)

    # 2. Yosys Synthesis
    yosys_script = f"read_verilog {flattened_v}; synth_gowin -top {top_module} -json {core_json}"
    res_yosys = subprocess.run(["yosys", "-e", ".*latch.*", "-p", yosys_script], capture_output=True, text=True)
    with open(os.path.join(logs_dir, "yosys-log.txt"), "w") as f:
        f.write(res_yosys.stdout + res_yosys.stderr)
    if res_yosys.returncode != 0:
        return ToolchainResult(False, "YOSYS", "Synthesis failed. Check logs/yosys-log.txt for details.")

    # 3. NextPNR Place-And-Route
    nextpnr_cmd = [
        "nextpnr-himbaechel", "--json", core_json, "--write", routed_json,
        "--device", device, "--vopt", f"family={family}", "--vopt", f"cst={cst_file}",
        "--report", os.path.join(logs_dir, "timing_report.json")
    ]
    res_pnr = subprocess.run(nextpnr_cmd, capture_output=True, text=True)
    with open(os.path.join(logs_dir, "nextpnr-log.txt"), "w") as f:
        f.write(res_pnr.stdout + res_pnr.stderr)
    if res_pnr.returncode != 0:
        return ToolchainResult(False, "PNR", "Place and Route failed. Check logs/nextpnr-log.txt.")

    # 4. Gowin Pack
    pack_cmd = ["gowin_pack", "-d", family, "-o", firmware_fs, routed_json]
    res_pack = subprocess.run(pack_cmd, capture_output=True, text=True)
    with open(os.path.join(logs_dir, "gowin-log.txt"), "w") as f:
        f.write(res_pack.stdout + res_pack.stderr)
    if res_pack.returncode != 0:
        return ToolchainResult(False, "PACK", "Bitstream generation failed. Check logs/gowin-log.txt.")

    return ToolchainResult(True, "SYNTH", "Bitstream generated successfully.", artifacts)