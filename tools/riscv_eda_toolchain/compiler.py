# tools/riscv_eda_toolchain/compiler.py

import os
import sys
import shutil
import subprocess
from .io_utils import get_nano_root, is_stale

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


def compile_asm(src_file, target_path, is_test_suite=False, custom_linker=None):
    """
    Compiles an assembly asset, isolating intermediate objects into /build/compiler-artifacts
    and delivering only the final 32-bit word aligned .text.hex and .data.hex files to the destination.
    """
    nano_root = get_nano_root()
    src_basename = os.path.splitext(os.path.basename(src_file))[0]
    
    # 1. Smart Target Parsing: Extract the directory and base output name cleanly
    if os.path.isdir(target_path) or target_path.endswith('/'):
        final_out_dir = os.path.abspath(target_path)
        out_basename = src_basename
    else:
        final_out_dir = os.path.abspath(os.path.dirname(target_path))
        out_basename = os.path.basename(target_path)
        # Strip common extensions if the user explicitly typed one out anyway
        if out_basename.endswith(('.hex', '.s', '.S', '.elf', '.o')):
            out_basename = os.path.splitext(out_basename)[0]

    # 2. Establish sandbox environments
    artifacts_dir = os.path.join(nano_root, "build", "compiler-artifacts")
    os.makedirs(artifacts_dir, exist_ok=True)
    os.makedirs(final_out_dir, exist_ok=True)

    # Define intermediate workspace file targets
    obj_file  = os.path.join(artifacts_dir, f"{src_basename}.o")
    elf_file  = os.path.join(artifacts_dir, f"{src_basename}.elf")
    dump_file = os.path.join(artifacts_dir, f"{src_basename}.dump")
    scratch_text_hex = os.path.join(artifacts_dir, f"{src_basename}.text.hex")
    scratch_data_hex = os.path.join(artifacts_dir, f"{src_basename}.data.hex")

    # Define final delivery names using your clean output prefix
    final_text_hex = os.path.join(final_out_dir, f"{out_basename}.text.hex")
    final_data_hex = os.path.join(final_out_dir, f"{out_basename}.data.hex")
    final_dump_file = os.path.join(final_out_dir, f"{out_basename}.dump")

    # --- REBUILD DEPENDENCY MONITOR ---
    # Now perfectly matches our upgraded list-capable is_stale engine
    if not is_stale(src_file, [final_text_hex, final_data_hex]):
        print(f"⏩ [PASS][0.0][GCC   ] Software targets are up to date: {out_basename}")
        return True

    print(f"🛠️  [****][0.0][GCC   ] Compiling software layout: {src_basename}.S -> {out_basename}.*")

    # --- ENV SETUP ---
    # Targets your exact link_generic.ld file choice
    default_linker = os.path.join(nano_root, "tools/env/link_generic.ld")
    linker_script = custom_linker if custom_linker else default_linker
    
    as_flags = ["-march=rv32i", "-mabi=ilp32", "-nostdlib", "-I" + os.path.join(nano_root, "tools/env")]
    
    if is_test_suite:
        test_env = os.path.join(nano_root, "sim/vendor/riscv-tests/custom_env")
        test_macros = os.path.join(nano_root, "sim/vendor/riscv-tests/isa/macros/scalar")
        as_flags.extend([f"-I{test_env}", f"-I{test_macros}"])
        linker_script = os.path.join(test_env, "link.ld")

    ld_flags = ["-m", "elf32lriscv", "-T", linker_script]

    # --- EXECUTION CHAIN ---
    # Step 1: Assemble (Notice the added "-c" flag!)
    res_gcc = subprocess.run(["riscv64-unknown-elf-gcc", "-c"] + as_flags + [src_file, "-o", obj_file], capture_output=True, text=True)
    if res_gcc.returncode != 0:
        print(f"❌ [FAIL][0.0][GCC   ] Compilation failed!\n{res_gcc.stderr}")
        return False

    # Step 2: Link
    res_ld = subprocess.run(["riscv64-unknown-elf-ld"] + ld_flags + [obj_file, "-o", elf_file], capture_output=True, text=True)
    if res_ld.returncode != 0:
        print(f"❌ [FAIL][0.0][LINKER] Linking failed!\n{res_ld.stderr}")
        return False

    # Step 3: Disassemble Dump
    try:
        with open(dump_file, "w") as df:
            subprocess.run(["riscv64-unknown-elf-objdump", "-d", elf_file], stdout=df, check=True)
    except Exception as e:
        print(f"❌ [FAIL][0.0][OBJDMP] Disassembly dump failed!\n{e}")
        return False

    # Step 4: Extract Sections
    subprocess.run(["riscv64-unknown-elf-objcopy", "-j", ".text", "-O", "verilog", elf_file, scratch_text_hex], check=True)
    subprocess.run(["riscv64-unknown-elf-objcopy", "-j", ".data", "-j", ".sdata", "-O", "verilog", elf_file, scratch_data_hex], check=True)

    # Step 5: Endian Alignment Formatting
    format_to_32bit(scratch_text_hex)
    format_to_32bit(scratch_data_hex)

    # Step 6: Export Deliverables with clean custom prefixes
    shutil.copy2(scratch_text_hex, final_text_hex)
    shutil.copy2(scratch_data_hex, final_data_hex)
    shutil.copy2(dump_file, final_dump_file)

    print(f"✅ [PASS][0.0][GCC   ] Hex matrices delivered to target: {final_out_dir}/{out_basename}.*")
    return True