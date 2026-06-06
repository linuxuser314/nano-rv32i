.text
.globl _start

_start:
    # -------------------------------------------------------------------------
    # PART 1: Extreme Immediate Boundaries
    # -------------------------------------------------------------------------
    # x1: Test absolute maximum positive 12-bit immediate (2047)
    addi x1, x0, 2047       

    # x2: Test absolute maximum negative 12-bit immediate (-2048 / 12'h800)
    # This checks for strict sign-extension edge cases.
    addi x2, x0, -2048      

    # x3: Add the two boundary intermediates together
    # Expected: 2047 + (-2048) = -1 (0xFFFFFFFF)
    add x3, x1, x2          

    # -------------------------------------------------------------------------
    # PART 2: Unsigned vs Signed Operator Anomalies
    # -------------------------------------------------------------------------
    # x4: Setup a negative register value via sign extension
    addi x4, x0, -1         # x4 = 0xFFFFFFFF

    # x5: slti (Signed) -> Is -1 < 1? True!
    slti x5, x4, 1          

    # x6: sltiu (Unsigned) -> Is 0xFFFFFFFF < 1? False!
    sltiu x6, x4, 1         

    # x7: sltiu boundary -> Is 0 < 0xFFFFFFFF (unsigned -1)? True!
    sltiu x7, x0, -1        

    # -------------------------------------------------------------------------
    # PART 3: Shift Value Truncation (The Shamt & 31 Rule)
    # -------------------------------------------------------------------------
    # Setup temporary registers with extreme values
    addi x28, x0, 1         # Target register to shift
    addi x29, x0, 36        # Shift amount = 36 (Binary: 0010_0100)
                            # The lower 5 bits [4:0] are cleanly 4.
    
    # x8: sll register shift left by 36. Core MUST truncate 36 to 4!
    # Expected: 1 << 4 = 16 (0x10)
    sll x8, x28, x29        

    # x9: srl register shift right logical by a saturated mask register
    # If x4 is 0xFFFFFFFF, its lower 5 bits are 31.
    # Expected: 0xFFFFFFFF >> 31 = 1
    srl x9, x4, x4          

    # -------------------------------------------------------------------------
    # PART 4: Advanced Arithmetic Shifting & Two's Complement Limits
    # -------------------------------------------------------------------------
    # Load 0x80000000 (Min Signed Int) into x30 using LUI
    lui x30, 0x80000        # x30 = 0x80000000
    
    # Load 0x7FFFFFFF (Max Signed Int) into x31 via LUI and ADDI
    lui x31, 0x7FFFF        
    addi x31, x31, 2000     # x31 = 0x7FFFFFFF
    addi x31, x31, 2000
    addi x31, x31, 95

    # x10: srai (Arithmetic Shift Immediate) on Min Signed Int
    # Shifting 0x80000000 right arithmetically by 1 bit MUST sign-fill with a 1.
    # Expected: 0xC0000000
    srai x10, x30, 1        

    # x11: sra (Arithmetic Shift Register) on Min Signed Int by a truncated shift
    # Shift right arithmetically by 33 bits -> Core truncates 33 to 1.
    # Expected: 0xC0000000
    addi x27, x0, 33        
    sra x11, x30, x27       

    # x12: sub boundary handling
    # Subtracting a negative number from a positive boundary: Max Pos - Min Neg
    # 0x7FFFFFFF - 0x80000000 = 0xFFFFFFFF (-1 due to two's complement rollover)
    sub x12, x31, x30       

    # x13: sub boundary underflow handling
    # Min Neg - 1
    # 0x80000000 - 1 = 0x7FFFFFFF (Should wrap around straight to Max Positive Int)
    addi x26, x0, 1
    sub x13, x30, x26       

    # -------------------------------------------------------------------------
    # PART 5: Logical Truth Masking Limits
    # -------------------------------------------------------------------------
    # x14: xori check with extreme sign extension boundary
    # Inverting an all-1s mask register with an all-1s sign-extended immediate (-1)
    # 0xFFFFFFFF XOR 0xFFFFFFFF = 0x00000000
    xori x14, x4, -1        

    # x15: andi check with extreme mask bounds
    # 0x7FFFFFFF ANDed with immediate -1 (sign extended to 0xFFFFFFFF)
    # Expected: 0x7FFFFFFF
    andi x15, x31, -1       

    # -------------------------------------------------------------------------
    # Terminal Freeze Point
    # -------------------------------------------------------------------------
loop:
    jal x0, loop
