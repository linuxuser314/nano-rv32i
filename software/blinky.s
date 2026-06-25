# blinky.s

.text
.globl _start

_start:
    li x1, 0
    li x2, 0x40000000
loop:
    addi x1, x1, 1
    sw x1, 0(x2)
    j loop
