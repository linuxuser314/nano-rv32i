.section .text
.global _start

_start:
  li x1, 0x12300293
  sw x1, 12(x0)
  nop
end:
    j end
