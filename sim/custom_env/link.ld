OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  /* Start execution and data placement contiguously at System RAM base */
  . = 0xC0000000;

  /* ================================================================== */
  /* CODE SECTION                                                       */
  /* ================================================================== */
  .text : {
    *(.text.init)      /* Crucial for riscv-tests startup macros */
    *(.text .text.*)
  } =0x00000013        /* Fill section gaps with NOPs (addi x0, x0, 0) */

  /* ================================================================== */
  /* READ-ONLY & INITIALIZED DATA                                       */
  /* ================================================================== */
  .rodata : {
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  }

  .data : {
    *(.data .data.*)
    *(.sdata .sdata.*) /* heavily used by riscv-tests */
    *(.tohost)         /* Captures test status outputs */
  }

  /* ================================================================== */
  /* UNINITIALIZED DATA                                                 */
  /* ================================================================== */
  .bss : {
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
  }

  _end = .;
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) *(.comment) }
}