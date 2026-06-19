/* sim/custom_env/link.ld */
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  /* Force the text section to start at 0x0 for our BRAM */
  . = 0x00000000;
  
  .text : { 
    *(.text.init) /* The _start vector must go first */
    *(.text) 
  }
  
  .data : { *(.data) }
  .bss : { *(.bss) }
  
  /* Discard standard library bloat */
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}