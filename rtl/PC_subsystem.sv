//The PC subsystem manages PC incrementation, stalling, jumping, and branching.
//The PC_increment gets set to true for stalls to prevent the PC from increasing.
//The PC_select is determined by the type of instruction.
//0 is normal instruction, 1 is for JAL, 2 is for JALR, and 3 is for branches.
//PC_plus_4 is the same as prev_PC when PC_increment is false.
`default_nettype none

module PC_subsystem(input  logic[31:0] prev_PC, imm, ALU_result,
                    input  logic[1:0] PC_select,
                    input  logic branch_flag, PC_increment,
                    output logic[31:0] new_PC, PC_plus_4, PC_plus_imm
                    );
    logic[31:0] jalr_addr;
    assign jalr_addr = {ALU_result[31:1], 1'b0};
    //These are pre-selection calculations that are also used for AUIPC and jal/jalr.
    //The PC_increment increments PC by 4 when 1 and 0 when 0, allowing the decoder to stall the PC.
    assign PC_plus_4 = prev_PC + {29'b0, PC_increment, 2'b0};
    assign PC_plus_imm = prev_PC + imm;
    //Selects the PC behavior for the next PC depending on PC_select.
    always_comb begin
        case(PC_select)
            0: new_PC = PC_plus_4;
            1: new_PC = PC_plus_imm;
            2: new_PC = jalr_addr;
            3: new_PC = branch_flag ? PC_plus_imm : PC_plus_4;
            default: new_PC = 32'b0;
        endcase
    end

endmodule
