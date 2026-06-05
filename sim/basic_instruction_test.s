# 1. DIRECTIVES (Telling the assembler how to organize the file)
.text
.globl _start

# 2. LABELS (Naming memory addresses)
_start:

    # 3. INSTRUCTIONS (The actual RISC-V code)

    #x1 = 8
    addi x1, x0, 5
    addi x1, x1, 3

    #x1 = 64
    slli x1, x1, 3
    #x1 = 2
    srli x1, x1, 5


    j end

fail:
    addi x3, x0, 1   # Set error code 1
    jal x0, end      # Jump to the end

success:
    addi x3, x0, 999 # Set success code

end:
    jal x0, end      # Infinite loop to stop the program