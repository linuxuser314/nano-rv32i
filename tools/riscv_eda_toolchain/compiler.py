# tools/riscv_eda_toolchain/compiler.py

import os
import shutil
import subprocess
from .io_utils import get_nano_root, is_stale, ToolchainResult

def format_to_32bit(filepath):
    """Parses a byte-hex file and transforms it into clean 32-bit big-endian words."""
    if not os.path.exists(filepath) or os.path.getsize(filepath) == 0:
        with open(filepath, 'w') as f:
            f.write('@00000000\n00000000\n')
        return

    with open(filepath, 'r') as f:
        raw_data = f.read().split()

    bytes_only = [b for b in raw_data if not b.startswith('@')]
    words = []
    for i in range(0, len(bytes_only), 4):
        if i + 3 < len(bytes_only):
            word32 = bytes_only[i+3] + bytes_only[i+2] + bytes_only[i+1] + bytes_only[i]
            words.append(word32)
            
    with open(filepath, 'w') as f:
        f.write('@00000000\n' + '\n'.join(words) + '\n')

def compile_asm(src_file, target_path, is_test_suite=False, custom_linker=None) -> ToolchainResult:
    nano_root = get_nano_root()
    src_basename = os.path.splitext(os.path.basename(src_file))[0]
    
    if os.path.isdir(target_path) or target_path.endswith('/'):
        final_out_dir = os.path.abspath(target_path)
        out_basename = src_basename
    else:
        final_out_dir = os.path.abspath(os.path.dirname(target_path))
        out_basename = os.path.basename(target_path)
        if out_basename.endswith(('.hex', '.s', '.S', '.elf', '.o')):
            out_basename = os.path.splitext(out_basename)[0]

    artifacts_dir = os.path.join(nano_root, "build", "compiler-artifacts")
    os.makedirs(artifacts_dir, exist_ok=True)
    os.makedirs(final_out_dir, exist_ok=True)

    obj_file  = os.path.join(artifacts_dir, f"{src_basename}.o")
    elf_file  = os.path.join(artifacts_dir, f"{src_basename}.elf")
    dump_file = os.path.join(artifacts_dir, f"{src_basename}.dump")
    scratch_text_hex = os.path.join(artifacts_dir, f"{src_basename}.text.hex")
    scratch_data_hex = os.path.join(artifacts_dir, f"{src_basename}.data.hex")

    final_text_hex = os.path.join(final_out_dir, f"{out_basename}.text.hex")
    final_data_hex = os.path.join(final_out_dir, f"{out_basename}.data.hex")
    final_dump_file = os.path.join(final_out_dir, f"{out_basename}.dump")

    artifacts = {"text_hex": final_text_hex, "data_hex": final_data_hex, "dump": final_dump_file}

    if not is_stale(src_file, [final_text_hex, final_data_hex]):
        return ToolchainResult(True, "GCC", f"Up to date: {out_basename}", artifacts)

    default_linker = os.path.join(nano_root, "tools/env/link_generic.ld")
    linker_script = custom_linker if custom_linker else default_linker
    as_flags = ["-march=rv32i", "-mabi=ilp32", "-nostdlib", "-I" + os.path.join(nano_root, "tools/env")]
    
    if is_test_suite:
        test_env = os.path.join(nano_root, "sim/vendor/riscv-tests/custom_env")
        test_macros = os.path.join(nano_root, "sim/vendor/riscv-tests/isa/macros/scalar")
        as_flags.extend([f"-I{test_env}", f"-I{test_macros}"])
        linker_script = os.path.join(test_env, "link.ld")

    ld_flags = ["-m", "elf32lriscv", "-T", linker_script]

    res_gcc = subprocess.run(["riscv64-unknown-elf-gcc", "-c"] + as_flags + [src_file, "-o", obj_file], capture_output=True, text=True)
    if res_gcc.returncode != 0:
        return ToolchainResult(False, "GCC", f"Compilation failed:\n{res_gcc.stderr}")

    res_ld = subprocess.run(["riscv64-unknown-elf-ld"] + ld_flags + [obj_file, "-o", elf_file], capture_output=True, text=True)
    if res_ld.returncode != 0:
        return ToolchainResult(False, "LINKER", f"Linking failed:\n{res_ld.stderr}")

    try:
        with open(dump_file, "w") as df:
            subprocess.run(["riscv64-unknown-elf-objdump", "-d", elf_file], stdout=df, check=True)
        subprocess.run(["riscv64-unknown-elf-objcopy", "-j", ".text", "-O", "verilog", elf_file, scratch_text_hex], check=True)
        subprocess.run(["riscv64-unknown-elf-objcopy", "-j", ".data", "-j", ".sdata", "-O", "verilog", elf_file, scratch_data_hex], check=True)
    except Exception as e:
        return ToolchainResult(False, "OBJDMP", f"Objcopy/Dump failed:\n{str(e)}")

    format_to_32bit(scratch_text_hex)
    format_to_32bit(scratch_data_hex)

    shutil.copy2(scratch_text_hex, final_text_hex)
    shutil.copy2(scratch_data_hex, final_data_hex)
    shutil.copy2(dump_file, final_dump_file)

    return ToolchainResult(True, "GCC", f"Successfully compiled {out_basename}", artifacts)