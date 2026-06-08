.section .text
.global _start

_start:
 li x1, 0x12300113 #addi x2, x0, 0x123
 sw x1, 16(x0) #store the instruction where the second nop is currently
 nop
 nop
 j loop
loop:
 j loop
 
