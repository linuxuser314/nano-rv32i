.text
.option norvc
.globl _start

_start:
    # Clear tracking registers
    addi x5, x0, 0          # Master Success Tracker (0 = Perfect)
    addi x6, x0, 0          # Step Marker

    # -------------------------------------------------------------------------
    # TEST 1: LUI (Load Upper Immediate)
    # -------------------------------------------------------------------------
    addi x6, x0, 1          # Step 1: LUI check
    lui x1, 0x12345         
    
    # Verify upper bits are set and lower bits are zero
    # Shift right by 12 logically; should equal 0x12345
    srli x2, x1, 12
    lui x3, 0x12345         # Temporary comparison vehicle
    srli x3, x3, 12
    bne x2, x3, fail        # If bits are corrupted, jump to fail

    # -------------------------------------------------------------------------
    # TEST 2: JAL (Jumping Ability)
    # -------------------------------------------------------------------------
    addi x6, x0, 2          # Step 2: JAL Jump check
    jal x0, jal_jump_pass   # Use x0 to test pure jump capability first
    jal x0, fail            # If it falls through, jump hardware failed
jal_jump_pass:

    # -------------------------------------------------------------------------
    # TEST 3: JAL (Return Value / Link Register)
    # -------------------------------------------------------------------------
    addi x6, x0, 3          # Step 3: JAL Link check
jal_link_anchor:
    jal x1, jal_link_target # Jump and store return address in x1
    jal x0, fail            # Block if it didn't jump
jal_link_target:
    
    # Math Verification: x1 must equal exactly (jal_link_anchor + 4)
    # Distance from jal_link_anchor to current_pc_1 is exactly 8 bytes.
    # Therefore, current_pc_1 minus 8 equals jal_link_anchor.
    # To check if x1 == jal_link_anchor + 4, then x1 + 4 must equal current_pc_1.
    addi x2, x1, 8          # x2 = Link Address + 4
current_pc_1:
    auipc x3, 0             # Captures the absolute address of this line
    bne x2, x3, fail        # If they do not match, the link calculation failed!

    # -------------------------------------------------------------------------
    # TEST 4: JALR (Jumping Ability)
    # -------------------------------------------------------------------------
    addi x6, x0, 4          # Step 4: JALR Jump check
    
    # We will build a target address using auipc + addi safely
jalr_jump_anchor:
    auipc x4, 0             # x4 = Address of jalr_jump_anchor
    addi x4, x4, 16         # Offset of 16 bytes points straight to jalr_jump_target
    jalr x0, x4, 0          # Jump unconditionally using x0
    jal x0, fail            # Trapped if jalr failed to fire
jalr_jump_target:

    # -------------------------------------------------------------------------
    # TEST 5: JALR (Return Value / Link Register)
    # -------------------------------------------------------------------------
    addi x6, x0, 5          # Step 5: JALR Link check
    
jalr_link_anchor:
    auipc x4, 0             # x4 = Address of jalr_link_anchor
    addi x4, x4, 16         # Offset of 16 bytes points to jalr_link_target
    jalr x2, x4, 0          # Jump and link into x2
    jal x0, fail            # Trapped if it missed the target
jalr_link_target:

    # Math Verification: x2 must equal exactly (jalr_link_anchor + 4)
    # Distance from jalr_link_anchor to current_pc_2 is exactly 12 bytes.
    # Therefore, x2 + 8 must equal current_pc_2.
    addi x3, x2, 8          # x3 = Return Address + 8
current_pc_2:
    auipc x4, 0             # Captures the absolute address of this line
    bne x3, x4, fail        # If they don't match, JALR link payload is corrupt!

    # -------------------------------------------------------------------------
    # TEST 6: AUIPC (Add Upper Immediate to PC)
    # -------------------------------------------------------------------------
    addi x6, x0, 6          # Step 6: AUIPC offset check
    
    # Test a non-zero shift scaling operation
auipc_calc_anchor:
    auipc x1, 0x00002       # x1 = auipc_calc_anchor + 0x00002000
    
    # Let's verify by manual offset calculation
    auipc x2, 0             # x2 = current PC
    addi x2, x2, -4         # Back-track to estimate auipc_calc_anchor PC
    lui x3, 0x00002         # Shift immediate manually to compare
    add x2, x2, x3          # x2 = estimated calculation target
    bne x1, x2, fail        # If they diverge, AUIPC sign/adder math is broken

    # -------------------------------------------------------------------------
    # SUCCESS PANIC RECOVERY
    # -------------------------------------------------------------------------
pass:
    addi x5, x0, 100        # Master Tracker = 100 (Clean Sweep Success!)
    jal x0, end

fail:
    addi x5, x0, -1         # Master Tracker = -1 (Hardware Failure triggered!)
    # Keep x6 active so you can read which Step ID triggered the drop

end:
    jal x0, end             # Infinite loop park