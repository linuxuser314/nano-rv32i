.section .text
.global _start

_start:
 li x1, 0
 j loop
loop:
 addi x1, x0, 1
 j loop
 
