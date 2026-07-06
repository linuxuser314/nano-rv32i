/* /workspaces/nano-rv32i/sim/custom_env/link.ld */
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  /* ================================================================== */
  /* ROM SECTION: Instructions live here                                */
  /* ================================================================== */
  . = 0x00000000;
  
  .text : { 
    *(.text.init)
    *(.text) 
  } =0x13000000   /* <-- THE AUIPC FIX: Fill all gaps in the text section with NOPs! (Notice the endianness is reversed)*/
  
  /* ================================================================== */
  /* RAM SECTION: Variables and working memory live here                */
  /* ================================================================== */
  . = 0xC0000000; 
  
  .data : { 
    *(.data) 
    *(.sdata)     /* The riscv-tests heavily use the .sdata (small data) section */
  }
  
  .bss : { 
    *(.bss) 
    *(.sbss) 
  }
  
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}