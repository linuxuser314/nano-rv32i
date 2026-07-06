OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    /* Separate physical zones mirroring your Harvard hardware buses */
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 16K
    RAM (rw) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
    /* Code section maps directly to Instruction ROM */
    .text : {
        *(.text._start)
        *(.text .text.*)
    } > ROM

    /* Data sections map directly to System RAM */
    .data : {
        *(.data .data.*)
        *(.sdata .sdata.*)
    } > RAM

    .bss : {
        *(.bss .bss.*)
        *(.sbss .sbss.*)
    } > RAM

    /* Discard unnecessary Linux ABI/metadata sections to keep hex files small */
    /DISCARD/ : {
        *(.comment)
        *(.riscv.attributes)
    }
}