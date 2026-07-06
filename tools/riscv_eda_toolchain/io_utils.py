# tools/riscv_eda_toolchain/io_utils.py

import os
import glob
import sys

def get_nano_root():
    """Retrieves the absolute path of NANO_ROOT, crashing safely if missing."""
    nano_root = os.environ.get("NANO_ROOT")
    if not nano_root:
        # Fallback to standard codespace/devcontainer path if variable isn't exported yet
        default_path = "/workspaces/nano-rv32i"
        if os.path.exists(default_path):
            return default_path
        print("❌ ERROR: $NANO_ROOT environment variable is not set!")
        print("Please export NANO_ROOT='/path/to/your/repo' or fix your shell environment.")
        sys.exit(1)
    return os.path.abspath(nano_root)

def get_rtl_files():
    """
    Recursively scans the $NANO_ROOT/rtl directory for all SystemVerilog (.sv) files.
    Guarantees that interface files are placed at the absolute beginning of the list
    so the compiler handles dependencies correctly.
    """
    nano_root = get_nano_root()
    rtl_base = os.path.join(nano_root, "rtl")
    
    if not os.path.exists(rtl_base):
        print(f"❌ ERROR: RTL directory not found at {rtl_base}")
        sys.exit(1)

    # 1. Recursive search for all .sv files across all subdirectories
    search_path = os.path.join(rtl_base, "**", "*.sv")
    all_files = [os.path.abspath(f) for f in glob.glob(search_path, recursive=True)]

    interfaces = []
    modules = []

    # 2. Separate into priority buckets
    for f in all_files:
        filename = os.path.basename(f).lower()
        filepath = f.lower()
        
        # Categorize as an interface if it contains '_if', 'interface', or lives in an interface folder
        if "_if" in filename or "interface" in filename or "interfaces" in filepath:
            interfaces.append(f)
        else:
            modules.append(f)

    # 3. Combine with interfaces strictly first (sorted alphabetically for deterministic builds)
    ordered_files = sorted(interfaces) + sorted(modules)
    
    return ordered_files

def is_stale(source_files, target_files):
    """
    Compares the modification timestamps of source file(s) against target file(s).
    Returns True if any target file needs to be rebuilt (i.e., if any target doesn't 
    exist or any source file is newer than any target file).
    """
    # Force both parameters into lists so we can loop over them uniformly
    if isinstance(source_files, str):
        source_files = [source_files]
    if isinstance(target_files, str):
        target_files = [target_files]

    # If even ONE target file is completely missing, the system is stale
    for target in target_files:
        if not os.path.exists(target):
            return True

    # Track down the absolute newest source file timestamp
    newest_source_time = 0
    for source in source_files:
        if os.path.exists(source):
            newest_source_time = max(newest_source_time, os.path.getmtime(source))

    # If any existing target is older than the newest source file, it's stale
    for target in target_files:
        if os.path.getmtime(target) < newest_source_time:
            return True

    return False