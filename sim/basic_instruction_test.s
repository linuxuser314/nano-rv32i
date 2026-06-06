# 1. DIRECTIVES (Telling the assembler how to organize the file)
.text
.globl _start

# 2. LABELS (Naming memory addresses)
_start:

    ## x1: Normal load upper immediate
    lui x1, 0x12345        

    # x2: Edge case load upper immediate (max boundary 20-bit value)
    lui x2, 0xFFFFF        

    # -------------------------------------------------------------------------
    # PART 2: I-Type ALU Tests (Immediates)
    # -------------------------------------------------------------------------
    # x3: addi normal positive addition
    addi x3, x0, 150       

    # x4: addi negative number handling (12-bit immediate is sign-extended)
    addi x4, x0, -50       

    # x5: addi max positive boundary calculation (12-bit max = 2047)
    addi x5, x0, 2047      

    # x6: slti (Set Less Than Immediate - Signed) -> True case (-50 < 150)
    slti x6, x4, 150       

    # x7: slti (Set Less Than Immediate - Signed) -> False case (150 < -50)
    slti x7, x3, -50       

    # x8: sltiu (Set Less Than Immediate Unsigned) -> Edge case
    # x4 is -50 (0xFFFFFFCE unsigned). 0xFFFFFFCE is NOT < 150 unsigned.
    sltiu x8, x4, 150      

    # x9: xori bitwise inversion edge case
    # 150 XOR -1 (Immediate 12'hFFF is sign-extended to 32'hFFFFFFFF)
    xori x9, x3, -1        

    # x10: ori bitwise manipulation
    ori x10, x0, 0x555     

    # x11: andi bitwise masking
    # 150 (0x96) AND 15 (0xF)
    andi x11, x3, 15       

    # x12: slli (Shift Left Logical Immediate)
    # 6 << 4
    slli x12, x11, 4       

    # x13: srli (Shift Right Logical Immediate)
    # 0xFFFFF000 shifted right logically by 12 bits drops 0s on the left
    srli x13, x2, 12       

    # x14: srai (Shift Right Arithmetic Immediate)
    # 0xFFFFF000 shifted right arithmetically copies the negative sign bit (1s)
    srai x14, x2, 12       

    # -------------------------------------------------------------------------
    # PART 3: R-Type ALU Tests (Register to Register)
    # -------------------------------------------------------------------------
    # Setup fresh, distinct constants into temporary tracking registers
    addi x29, x0, 1000     # Input A (Positive)
    addi x30, x0, 2000     # Input B (Positive)
    addi x31, x0, -500     # Input C (Negative)

    # x15: add normal operation
    add x15, x29, x30      

    # x16: add overflow/wrap edge case
    # -1 (from x14) + 1 (from x13)
    add x16, x14, x13      

    # x17: sub normal operation
    sub x17, x30, x29      

    # x18: sub underflow/wrap edge case
    # 0 - 1 (from x13)
    sub x18, x0, x13       

    # x19: sll register-driven shift left
    # Shift value 1 left by 5 bits (amount driven by register x28)
    addi x19, x0, 1
    addi x28, x0, 5        
    sll x19, x19, x28      

    # x20: slt signed register check -> True case (-500 < 1000)
    slt x20, x31, x29      

    # x21: slt signed register check -> False case (1000 < -500)
    slt x21, x29, x31      

    # x22: sltu unsigned register check -> Edge case
    # Unsigned -500 (0xFFFFFE0C) is NOT < 1000 (0x3E8)
    sltu x22, x31, x29     

    # x23: xor register matching clear check
    xor x23, x29, x29      

    # x24: srl register shift right logical edge case
    # Shift 0xFFFFF000 right logically by 31 bits
    addi x28, x0, 31
    srl x24, x2, x28       

    # x25: sra register shift right arithmetic edge case
    # Shift 0xFFFFF000 right arithmetically by 31 bits
    sra x25, x2, x28       

    # Clean logical inputs setup for or/and checks
    addi x29, x0, 0x555    
    addi x30, x0, 0x222    

    # x26: or register operation (0x555 | 0x222)
    or x26, x29, x30       

    # x27: and register operation (0x555 & 0x222)
    and x27, x29, x30      

    # -------------------------------------------------------------------------
    # Terminal Freeze Point
    # -------------------------------------------------------------------------
    # This is the single, isolated jump in the entire file. It creates an 
    # infinite loop at the very bottom to cleanly park your simulation clock 
    # so you can audit the final state of the register file.
loop:
    jal x0, loop