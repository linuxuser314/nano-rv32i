.text
.globl _start

_start:
    # Initialize our test tracker (x3) to 0.
    # EXPECTED SIGNALS: RegWrite=1, ALUSrc=1 (Imm), Branch=0, Jump=0
    addi x3, x0, 0          

    # -------------------------------------------------------------------------
    # TEST 1: Basic ADDI
    # -------------------------------------------------------------------------
    addi x3, x0, 1          # Set tracker to 1
    
    # Setup test registers
    addi x1, x0, 10         # x1 = 10
    addi x2, x0, 10         # x2 = 10

    # -------------------------------------------------------------------------
    # TEST 2: BNE (Branch Not Equal) - Fallthrough
    # -------------------------------------------------------------------------
    addi x3, x0, 2          # Set tracker to 2
    
    # EXPECTED SIGNALS for BNE: 
    # Branch=1, RegWrite=0, ALUSrc=0 (Reg), ALUOp=Subtract (to compare)
    # The ALU should output 0 (since 10-10=0), so the branch condition is FALSE.
    # PC should become PC + 4.
    bne x1, x2, fail        # 10 != 10 is false, should fall through

    # -------------------------------------------------------------------------
    # TEST 3: BEQ (Branch Equal) - Taken
    # -------------------------------------------------------------------------
    addi x3, x0, 3          # Set tracker to 3
    
    # EXPECTED SIGNALS for BEQ:
    # Branch=1, RegWrite=0, ALUSrc=0 (Reg), ALUOp=Subtract
    # The ALU should output 0, so the branch condition is TRUE.
    # PC should become PC + Imm.
    beq x1, x2, pass_beq    # 10 == 10 is true, MUST branch over the next instruction
    
    # If BEQ failed, it will fall through to here and crash.
    jal x0, fail            
pass_beq:

    # -------------------------------------------------------------------------
    # TEST 4: ADD (Register-Register)
    # -------------------------------------------------------------------------
    addi x3, x0, 4          # Set tracker to 4
    
    addi x1, x0, 5          # x1 = 5
    addi x2, x0, 7          # x2 = 7
    
    # EXPECTED SIGNALS for ADD:
    # RegWrite=1, ALUSrc=0 (Reg), Branch=0, Jump=0, ALUOp=Add
    add x4, x1, x2          # x4 = 5 + 7 = 12
    
    addi x5, x0, 12         # Setup expected answer
    bne x4, x5, fail        # Did x4 equal 12? If not, fail.

    # -------------------------------------------------------------------------
    # TEST 5: JAL (Jump and Link)
    # -------------------------------------------------------------------------
    addi x3, x0, 5          # Set tracker to 5
    
    # EXPECTED SIGNALS for JAL:
    # Jump=1, RegWrite=1, ALUSrc=X (Don't care), MemtoReg=2 (or routed to PC+4)
    # PC should become PC + Imm. x4 should get PC + 4.
    jal x4, pass_jal        
    
    jal x0, fail            # This should be jumped over
pass_jal:                   # jal lands here
    
    # Check if the link register (x4) was written properly. It shouldn't be 0.
    beq x4, x0, fail        

    # -------------------------------------------------------------------------
    # TEST 6: JALR (Jump and Link Register)
    # -------------------------------------------------------------------------
    addi x3, x0, 6          # Set tracker to 6
    
    # To test JALR, we need an absolute address in a register.
    # We will use jal to get the current PC into x5, then add an offset.
    jal x5, 1f
1:
    # x5 now holds the PC of label '1'.
    # Instructions are 4 bytes. We want to jump over the next 2 instructions (8 bytes).
    addi x5, x5, 8
    
    # EXPECTED SIGNALS for JALR:
    # Jump=1, RegWrite=1, ALUSrc=1 (Imm, to add offset to base reg)
    # PC becomes (x5 + 0) & ~1.
    jalr x6, x5, 0          
    
    jal x0, fail            # Skipped by jalr
    jal x0, fail            # Skipped by jalr
    
    # JALR lands here!

    # -------------------------------------------------------------------------
    # SUCCESS
    # -------------------------------------------------------------------------
    addi x3, x0, 999        # 999 (0x3E7) indicates success!
end:
    jal x0, end             # Infinite loop on pass

fail:
    jal x0, fail            # Infinite loop on fail. Check x3 to see which test broke.
    