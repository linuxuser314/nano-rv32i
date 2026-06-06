.text
.globl _start

_start:
    # -------------------------------------------------------------------------
    # PART 1: Hardware State Setup (Restricted to x1 - x14)
    # -------------------------------------------------------------------------
    addi x1, x0, 0          # Constant 0
    addi x2, x0, 1          # Smallest positive integer
    addi x3, x0, -1         # All-ones mask (0xFFFFFFFF)
    
    # Load 0x80000000 (Minimum Signed Integer)
    lui x4, 0x80000        
    
    # Load 0x7FFFFFFF (Maximum Signed Integer)
    lui x5, 0x7FFFF        
    ori x5, x5, 0x7FF       
    addi x5, x5, 1024       
    addi x5, x5, 1024       

    # Baseline progress tracker initialization
    addi x15, x0, 0         

    # -------------------------------------------------------------------------
    # EDGE CASE 1: Equal/Not-Equal Boundary (Zero vs Negative Maxima)
    # -------------------------------------------------------------------------
    addi x15, x0, 1         # Test ID 1
    beq x4, x1, fail        # 0x80000000 == 0 -> FALSE. Must NOT jump.
    
    bne x4, x1, 1f          # 0x80000000 != 0 -> TRUE. MUST jump.
    jal x0, fail
1:

    # -------------------------------------------------------------------------
    # EDGE CASE 2: Signed "Less Than" Flipping (Positive vs Max Negative)
    # -------------------------------------------------------------------------
    addi x15, x0, 2         # Test ID 2
    blt x2, x4, fail        # Is 1 < 0x80000000 (Signed)? 
                            # 1 < -2147483648 is FALSE. Must NOT jump.
    
    blt x4, x2, 1f          # Is -2147483648 < 1 (Signed)? TRUE. MUST jump.
    jal x0, fail
1:

    # -------------------------------------------------------------------------
    # EDGE CASE 3: Signed "Greater or Equal" Saturation Limits
    # -------------------------------------------------------------------------
    addi x15, x0, 3         # Test ID 3
    bge x4, x5, fail        # Is Min Signed >= Max Signed? 
                            # -2147483648 >= 2147483647 is FALSE. Must NOT jump.
    
    bge x5, x4, 1f          # Is Max Signed >= Min Signed? TRUE. MUST jump.
    jal x0, fail
1:

    # -------------------------------------------------------------------------
    # EDGE CASE 4: Unsigned "Less Than" Deep Inversion (0xFFFFFFFF vs 1)
    # -------------------------------------------------------------------------
    # This is a classic breakpoint. Signed, -1 < 1. Unsigned, 4.29B > 1.
    addi x15, x0, 4         # Test ID 4
    bltu x3, x2, fail       # Is 0xFFFFFFFF < 1 (Unsigned)? FALSE. Must NOT jump.
    
    bltu x2, x3, 1f         # Is 1 < 0xFFFFFFFF (Unsigned)? TRUE. MUST jump.
    jal x0, fail
1:

    # -------------------------------------------------------------------------
    # EDGE CASE 5: Unsigned "Greater or Equal" with 0x80000000
    # -------------------------------------------------------------------------
    # Unsigned, 0x80000000 (2,147,483,648) is greater than 0.
    addi x15, x0, 5         # Test ID 5
    bgeu x1, x4, fail       # Is 0 >= 2147483648 (Unsigned)? FALSE. Must NOT jump.
    
    bgeu x4, x1, 1f         # Is 2147483648 >= 0 (Unsigned)? TRUE. MUST jump.
    jal x0, fail
1:

    # -------------------------------------------------------------------------
    # EDGE CASE 6: Strict Self-Comparison Identity Checks
    # -------------------------------------------------------------------------
    addi x15, x0, 6         # Test ID 6
    bne x3, x3, fail        # Is -1 != -1? FALSE. Must NOT jump.
    blt x3, x3, fail        # Is -1 < -1? FALSE. Must NOT jump.
    bltu x3, x3, fail       # Is -1 < -1 (Unsigned)? FALSE. Must NOT jump.
    
    beq x3, x3, 1f          # Is -1 == -1? TRUE. MUST jump.
    jal x0, fail
1:

    # -------------------------------------------------------------------------
    # SUCCESS ANCHOR
    # -------------------------------------------------------------------------
pass:
    addi x15, x0, 999       # Safe completion code!
    jal x0, end

fail:
    # If any branch fails, execution lands here. 
    # Check register x15 in Surfer to see the exact Test ID that tripped.
    addi x14, x0, 0x600
    addi x14, x0, 0x500     # Diagnostic flag
    addi x14, x0, 0x0AD     # Diagnostic flag
    jal x0, end

end:
    jal x0, end             # Infinite loop park
