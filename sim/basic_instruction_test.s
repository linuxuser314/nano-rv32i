# basic_instruction_test.s
# Self-contained bare-metal test suite for unprivileged RV32I
# Memory constraint: 4KB. Base Address: 0x00000000.
# Constraints: No CSRs, no misaligned access, 1-cycle store->load hazard.

.section .text
.align 2
.globl _start

_start:
    # Initialize TESTNUM register (x28 / t3) to 0
    # Monitor x28 in Surfer. If it stops updating, the test failed.
    li x28, 0

# ==============================================================================
# MACROS
# ==============================================================================

# Test R-Type ALU Instructions
.macro TEST_R testnum, op, expected, val1, val2
    li x28, \testnum
    li x1, \val1
    li x2, \val2
    \op x3, x1, x2
    li x4, \expected
    bne x3, x4, fail
.endm

# Test I-Type ALU Instructions
.macro TEST_I testnum, op, expected, val1, imm
    li x28, \testnum
    li x1, \val1
    \op x3, x1, \imm
    li x4, \expected
    bne x3, x4, fail
.endm

# ==============================================================================
# ALU EDGE CASE TESTS
# ==============================================================================

    # --- ADD / ADDI Edge Cases ---
    TEST_I 1, addi, 0x00000000, 0x00000000, 0
    TEST_I 2, addi, 0x7FFFF7FF, 0x7FFFFFFF, -2048 # Max positive + min negative
    TEST_I 3, addi, 0x800007FF, 0x80000000, 2047  # Min negative + max positive
    
    TEST_R 10, add, 0x00000000, 0xFFFFFFFF, 0x00000001 # -1 + 1 = 0
    TEST_R 11, add, 0x80000000, 0x7FFFFFFF, 0x00000001 # Positive overflow to negative
    TEST_R 12, add, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF # Negative underflow to positive

    # --- SUB Edge Cases ---
    TEST_R 20, sub, 0x00000000, 0x00000000, 0x00000000
    TEST_R 21, sub, 0xFFFFFFFF, 0x00000000, 0x00000001 # 0 - 1 = -1
    TEST_R 22, sub, 0x7FFFFFFF, 0x80000000, 0x00000001 # Min negative - 1 = Max positive

    # --- SLT / SLTU (Signed vs Unsigned Comparisons) ---
    TEST_R 30, slt,  1, 0x80000000, 0x7FFFFFFF # Signed:   -IntMax < +IntMax -> 1 (True)
    TEST_R 31, sltu, 0, 0x80000000, 0x7FFFFFFF # Unsigned: +IntMax > +IntMax -> 0 (False)
    TEST_R 32, slt,  0, 0x00000000, 0xFFFFFFFF # Signed:   0 < -1 -> 0 (False)
    TEST_R 33, sltu, 1, 0x00000000, 0xFFFFFFFF # Unsigned: 0 < Unsigned Max -> 1 (True)

    # --- LOGICAL Edge Cases ---
    TEST_R 40, xor, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555
    TEST_R 41, and, 0x00000000, 0xAAAAAAAA, 0x55555555
    TEST_R 42, or,  0xFFFFFFFF, 0xAAAAAAAA, 0x55555555

    # --- SHIFT Edge Cases (Arithmetic vs Logical) ---
    TEST_I 50, slli, 0x80000000, 0x00000001, 31
    TEST_I 51, srli, 0x00000001, 0x80000000, 31
    TEST_I 52, srai, 0xFFFFFFFF, 0x80000000, 31 # Sign bit must copy through
    TEST_I 53, srai, 0x00000000, 0x7FFFFFFF, 31 # Positive sign bit must stay 0
    TEST_R 54, sra,  0xFFFFFFFF, 0x80000000, 31 # (Fixed!) Shift arithmetic right by 31

# ==============================================================================
# UPPER IMMEDIATE & PC-RELATIVE TESTS
# ==============================================================================

    # Test 60: LUI
    li x28, 60
    lui x1, 0x80000
    li x2, 0x80000000
    bne x1, x2, fail

    # Test 61: AUIPC
    li x28, 61
1:  auipc x1, 0          # x1 should exactly equal the address of label 1
    la x2, 1b
    bne x1, x2, fail

# ==============================================================================
# BRANCH AND JUMP TESTS
# ==============================================================================

    # Test 70: BEQ, BNE, BLT, BGE
    li x28, 70
    li x1, 1
    li x2, -1
    beq x1, x2, fail     # 1 != -1
    bge x2, x1, fail     # -1 is NOT >= 1
    blt x1, x2, fail     # 1 is NOT < -1
    bltu x2, x1, fail    # Unsigned: 0xFFFFFFFF is NOT < 1
    bne x1, x2, branch_pass
    j fail               # Shouldn't hit this

branch_pass:
    
    # Test 80: JAL and JALR
    li x28, 80
    jal x5, jump_target
    j fail               # Shouldn't hit this
jump_target:
    la x6, jump_target2
    jalr x0, x6, 0
    j fail               # Shouldn't hit this
jump_target2:

# ==============================================================================
# MEMORY TESTS (Handling Structural Hazard)
# ==============================================================================

    la x10, test_memory  # Load address of our data section safe space

    # Test 90: Word Store/Load
    li x28, 90
    li x1, 0xDEADBEEF
    sw x1, 0(x10)
    nop                  # 1 cycle separation for BRAM read-first behavior
    lw x2, 0(x10)
    li x3, 0xDEADBEEF
    bne x2, x3, fail

    # Test 91: Byte Store, Sign-Extended Load vs Zero-Extended Load
    li x28, 91
    li x1, 0x80          # High bit set for a byte
    sb x1, 4(x10)        
    nop
    lb x2, 4(x10)        # Should sign-extend to 0xFFFFFF80
    li x3, 0xFFFFFF80
    bne x2, x3, fail

    lbu x2, 4(x10)       # Should zero-extend to 0x00000080
    li x3, 0x00000080
    bne x2, x3, fail

    # Test 92: Halfword Store/Load
    li x28, 92
    li x1, 0x8000
    sh x1, 8(x10)        
    nop
    lh x2, 8(x10)        # Should sign-extend to 0xFFFF8000
    li x3, 0xFFFF8000
    bne x2, x3, fail

    lhu x2, 8(x10)       # Should zero-extend to 0x00008000
    li x3, 0x00008000
    bne x2, x3, fail

# ==============================================================================
# FENCE.I TEST
# ==============================================================================
    li x28, 100
    # Hardcoded 'fence.i' machine code to bypass strict assembler checks.
    # Instruction format: 0000 0000 0000 0000 0001 0000 0000 1111
    .word 0x0000100f 

# ==============================================================================
# TEST CONCLUSION
# ==============================================================================

pass:
    li x28, 999          # 999 indicates full pass
    j pass               # Infinite loop to catch end of simulation

fail:
    j fail               # Infinite loop. Check x28 in your waveform to see what failed!

# ==============================================================================
# DATA SECTION (Fits well within 4KB memory)
# ==============================================================================
.section .data
.align 4
test_memory:
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    