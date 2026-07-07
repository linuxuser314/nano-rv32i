# tools/riscv_eda_toolchain/io_utils.py

import os
import glob
import sys
from dataclasses import dataclass, field
from typing import Dict

@dataclass
class ToolchainResult:
    """Standardized return object for all toolchain operations."""
    success: bool
    stage: str
    message: str
    artifacts: Dict[str, str] = field(default_factory=dict)

def get_nano_root() -> str:
    """Retrieves the absolute path of NANO_ROOT, crashing safely if missing."""
    nano_root = os.environ.get("NANO_ROOT")
    if not nano_root:
        default_path = "/workspaces/nano-rv32i"
        if os.path.exists(default_path):
            return default_path
        print("❌ ERROR: $NANO_ROOT environment variable is not set!")
        sys.exit(1)
    return os.path.abspath(nano_root)

def get_rtl_files() -> list:
    """Recursively scans the rtl directory, guaranteeing interfaces are loaded first."""
    nano_root = get_nano_root()
    rtl_base = os.path.join(nano_root, "rtl")
    
    if not os.path.exists(rtl_base):
        print(f"❌ ERROR: RTL directory not found at {rtl_base}")
        sys.exit(1)

    search_path = os.path.join(rtl_base, "**", "*.sv")
    all_files = [os.path.abspath(f) for f in glob.glob(search_path, recursive=True)]

    interfaces = []
    modules = []

    for f in all_files:
        filename = os.path.basename(f).lower()
        filepath = f.lower()
        if "_if" in filename or "interface" in filename or "interfaces" in filepath:
            interfaces.append(f)
        else:
            modules.append(f)

    return sorted(interfaces) + sorted(modules)

def is_stale(source_files, target_files) -> bool:
    """Checks timestamps to determine if a rebuild is necessary."""
    if isinstance(source_files, str): source_files = [source_files]
    if isinstance(target_files, str): target_files = [target_files]

    for target in target_files:
        if not os.path.exists(target):
            return True

    newest_source_time = 0
    for source in source_files:
        if os.path.exists(source):
            newest_source_time = max(newest_source_time, os.path.getmtime(source))

    for target in target_files:
        if os.path.getmtime(target) < newest_source_time:
            return True

    return False