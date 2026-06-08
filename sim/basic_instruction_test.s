.section .text
.global _start

_start:
 lw x1, 0(x0)
 lw x2, 4(x0)
 lw x3, 8(x0)
 lw x4, 12(x0)
 j loop
loop:
 j loop
 
