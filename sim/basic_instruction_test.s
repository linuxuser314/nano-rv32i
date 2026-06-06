.text
.globl _start

_start:
    # Initialize track registers
    addi x15, x0, 0
    addi x1, x0, 0
    addi x2, x0, 0

    # -------------------------------------------------------------------------
    # TEST 1: JAL (Jump and Link) Relative Verification
    # -------------------------------------------------------------------------
    addi x15, x0, 1         # Test ID 1
    
    # jal sitting at address PC_A. It should jump forward to label 'jal_target'
    # and it MUST write (PC_A + 4) into register x1.
jal_anchor:
    jal x1, jal_target      
    jal x0, fail            # Trapped if jal didn't jump!

jal_target:
    # Verify that x1 holds exactly the address of 'jal_anchor' + 4.
    # We use a relative PC calculation trick: '.' is our current PC.
    # The distance from 'jal_anchor' to the instruction below is exactly 8 bytes.
    # Therefore, (Current PC - 8) equals the address of 'jal_anchor'.
    # Since x1 should hold (jal_anchor + 4), then: x1 + 4 should EQUAL current PC!
    
    # Let's perform the verification math safely:
    addi x3, x1, 4          # x3 = x1 + 4 -> Should equal the PC of the next line
current_pc_1:
    auipc x4, 0             # x4 gets the exact value of 'current_pc_1'
    bne x3, x4, fail        # If the link register value is wrong, fail!

    # -------------------------------------------------------------------------
    # TEST 2: AUIPC (Add Upper Immediate to PC) Absolute Building
    # -------------------------------------------------------------------------
    addi x15, x0, 2         # Test ID 2

    # We want to build an absolute address to a far-away target using auipc + addi.
    # auipc moves an immediate left 12 bits and adds it to the current PC.
auipc_anchor:
    auipc x5, 0x00000       # x5 = address of 'auipc_anchor'
    
    # Calculate the exact byte offset from 'auipc_anchor' to 'jalr_target' below.
    # Count: auipc (4), addi (4), jalr (4), addi (4), jal (4), target is 20 bytes away.
    addi x5, x5, 20         # x5 now holds the absolute memory address of 'jalr_target'

    # -------------------------------------------------------------------------
    # TEST 3: JALR (Jump and Link Register) Absolute Verification
    # -------------------------------------------------------------------------
    addi x15, x0, 3         # Test ID 3

    # jalr jumps to the absolute address stored inside x5.
    # It must also write the return address (PC_B + 4) into register x2.
jalr_anchor:
    jalr x2, x5, 0          # Jump to address in x5 + offset 0
    jal x0, fail            # Trapped if jalr didn't jump!

    # -------------------------------------------------------------------------
    # TEST 4: LUI (Load Upper Immediate) Data Independence Integration
    # -------------------------------------------------------------------------
    # We place a dummy block here. If jalr works, it will leap completely OVER this.
    lui x10, 0xABCDE
    jal x0, fail            # If jalr targeted wrong, it might slip here.

jalr_target:
    # Verify that x2 holds exactly the address of 'jalr_anchor' + 4.
    # The distance from 'jalr_anchor' to this exact line is 12 bytes.
    # Therefore, (x2 + 8) should equal our current PC.
    addi x3, x2, 8
current_pc_2:
    auipc x4, 0             # x4 gets the exact value of 'current_pc_2'
    bne x3, x4, fail        # If jalr link address was corrupt, fail!

    # -------------------------------------------------------------------------
    # SUCCESS ANCHOR
    # -------------------------------------------------------------------------
pass:
    addi x15, x0, 999       # Safe completion code!
    jal x0, end

fail:
    addi x14, x0, 0x0AD     # Visible flag for Surfer trace view
    addi x14, x14, 0x500
    addi x14, x14, 0x600
    jal x0, end

end:
    jal x0, end             # Infinite loop stall
