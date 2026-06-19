# sim/tohost_test.s
# A bare-metal test to verify MMIO tohost wire routing in waveforms.

.section .text
.align 2
.globl _start

_start:
    # 1. Load the tohost MMIO address (0x40000000) into t0 (x5)
    lui t0, 0x40000

    # 2. Build a recognizable hex pattern (0xCAFEBABE) in t1 (x6)
    li t1, 0xCAFEBABE

    # 3. Write 0xCAFEBABE to tohost
    # Watch the 'tohost' wire in Surfer on the cycle this executes!
    sw t1, 0(t0)

    # 4. Load the official riscv-tests "PASS" code (0x1)
    li t1, 1

    # 5. Write 0x00000001 to tohost
    sw t1, 0(t0)

infinite_loop:
    j infinite_loop