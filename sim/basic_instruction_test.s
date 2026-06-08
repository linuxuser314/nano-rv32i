.section .text
.global _start

_start:
    # ----------------------------------------------------------------
    # Setup Phase (Using working instructions: LUI, ADDI, SW)
    # ----------------------------------------------------------------
    # 1. Construct the machine code for: addi x1, x0, 42
    #    The 32-bit hex representation for "addi x1, x0, 42" is 0x02a00093
    lui   x5, 0x02a00          # Upper 20 bits
    addi  x5, x5, 0x093        # Lower 12 bits. x5 now holds 0x02a00093

    # 2. Get the target address where we will inject this instruction
    #    We use auipc to find out where we are dynamically
    auipc x6, 0                # x6 = current PC
    addi  x6, x6, 28           # Offset to the 'target_slot' label below

    # ----------------------------------------------------------------
    # Test Phase: Execute the Store Word (sw)
    # ----------------------------------------------------------------
    sw    x5, 0(x6)            # Overwrite the NOP at 'target_slot' with our ADDI

    # ----------------------------------------------------------------
    # Execution Phase
    # ----------------------------------------------------------------
target_slot:
    nop                        # This gets overwritten by 'addi x1, x0, 42'
    
    # ----------------------------------------------------------------
    # Verification Phase (Using working instructions: BRANCH, ADDI)
    # ----------------------------------------------------------------
    # Prepare our success/fail flags
    addi  x2, x0, 42           # Expected value
    addi  x3, x0, 1            # Success flag (1)
    
    # Check if x1 matches the expected 42
    beq   x1, x2, test_pass
    
test_fail:
    li  x4, 0xDEAD       # x4 = 0xDEAD (FAIL)
    beq   x0, x0, end          # Infinite loop on failure

test_pass:
    addi  x4, x3, 0            # x4 = 1 (PASS!)

end:
    beq   x0, x0, end          # Infinite loop to halt execution
