# 1. DIRECTIVES (Telling the assembler how to organize the file)
.text
.globl _start

# 2. LABELS (Naming memory addresses)
_start:

    # 3. INSTRUCTIONS (The actual RISC-V code)

    #x1 = 8 - PASSED
    addi x1, x0, 5
    addi x1, x1, 3

    #x1 = 64 - PASSED
    slli x1, x1, 3

    #x1 = 2 - PASSED
    srli x1, x1, 5

    #loads multiple immediates with lui and addi
    li x2, 1000000000
    li x3, 1000000002
    sub x4, x3, x2
    #x4 = 1000002 - 100000 = 2

    #if they are equal it will continue to li into x5
    bne x4, x1, end
    li x5, 16


    j end
end:
    nop              # So I can visualize that it has got to the end because the PC is flip-flopping
    jal x0, end      # Infinite loop to stop the program