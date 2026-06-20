/* /workspaces/nano-rv32i/sim/custom_env/link.ld */
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  
  .text : { 
    *(.text.init)
    *(.text) 
  } =0x13000000   /* <-- THE AUIPC FIX: Fill all gaps in the text section with NOPs! (Notice the endiannes is reversed)*/
  
  .data : { *(.data) }
  .bss : { *(.bss) }
  
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}