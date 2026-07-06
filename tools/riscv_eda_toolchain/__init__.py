# tools/riscv_eda_toolchain/__init__.py

"""
RISC-V EDA Toolchain Master Package
Centralizes compilation, simulation, and EDA tasks for the nano-rv32i core.
"""

# 1. Define the version of your toolchain
__version__ = "1.0.0"

# 2. Pull functions from submodules up to the package surface
#from .compiler import compile_asm, slice_elf, format_to_32bit
#from .simulator import compile_hdl, execute_sim
from .io_utils import get_nano_root, get_rtl_files, is_stale
# 3. Explicitly define what is exposed when someone runs "from riscv_eda_toolchain import *"
__all__ = [
    "get_nano_root",
    "get_rtl_files",
    "is_stale"
]