.text
.globl _start

_start:
   addi x1, x0, 1
   addi x2, x0, 2
   addi x3, x0, 3
   addi x4, x0, 4
   addi x5, x0, 5

   addi x6, x0, -6
   addi x7, x0, -7
   addi x8, x0, 8
   addi x9, x0, -9
   addi x10, x0, -10

   addi x11, x0, 1
   addi x12, x0, 2
   addi x13, x0, 3
   addi x14, x0, 4
   addi x15, x0, 5

   addi x16, x0, -6
   addi x17, x0, -7
   addi x18, x0, 8
   addi x19, x0, -9
   addi x20, x0, -10

   beq x1, x2, .+4
   li x30, 1
   nop
   bne x20, x10, .+4
   li x30, 2
   nop
   blt x4, x10, .+4
   li x30, 3
   nop
   bge x20, x19, .+4
   li x30, 4
   nop
   bltu x1, x0, .+4
   li x30, 5
   nop
   bgeu x13, x15, .+4
   li x30, 6
   nop


loop:
    jal x0, loop
fail:
    addi x31, x0, 1
    j loop
