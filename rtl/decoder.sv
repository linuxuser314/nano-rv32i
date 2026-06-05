`default_nettype none

module decoder(input  logic[31:0] instruction,
               input  logic        MEMORY_MISALIGNED_ERROR,
                                   INSTRUCTION_MISALIGNED_ERROR,
                                   MEMORY_OUT_OF_BOUNDS_ERROR,
                output logic I, S, B, U, J, is_byte, is_half, is_unsigned, is_store,
                             eq, lt, ltu, negate, sub, PC_increment, RF_write_enable,
                             is_right_shift, is_arithmetic_shift, ALU_src,
                output logic[1:0] mask_ctrl, PC_select,
                output logic[2:0] result_select
                );

    logic[16:0] instruction_data;
    logic UNDEFINED_SYSTEM_INSTRUCTION, INVALID_INSTRUCTION;
    assign instruction_data = {instruction[6:0], instruction[14:12], instruction[31:25]};
    always_comb begin
        I = 0; S = 0; B = 0; U = 0; J = 0; is_byte = 0; is_half = 0; is_unsigned = 0; is_store = 0;
            eq = 0; lt = 0; ltu = 0; negate = 0; sub = 0;
            PC_increment = 1;//Set to 1 to progress to the next instruction!
            is_right_shift = 0; is_arithmetic_shift = 0; ALU_src = 0; mask_ctrl = 0; PC_select = 0;
            result_select = 0;  RF_write_enable = 0;
            UNDEFINED_SYSTEM_INSTRUCTION = 0; INVALID_INSTRUCTION = 0;
        if(MEMORY_MISALIGNED_ERROR |
           INSTRUCTION_MISALIGNED_ERROR | MEMORY_OUT_OF_BOUNDS_ERROR) begin
                PC_increment = 0;
            end
        else begin
            PC_increment = 1;
            casez(instruction_data)
            //Format opcode_funct3_funct7
                //ALU I and R-type instructions
                17'b0110011_000_0100000: begin RF_write_enable = 1; ALU_src = 1; sub = 1; result_select = 3; end//sub
                17'b0110011_000_0000000: begin RF_write_enable = 1; ALU_src = 1; result_select = 3; end//add
                17'b0010011_000_???????: begin RF_write_enable = 1; I = 1; result_select = 3; end//addi
                17'b0110011_001_0000000: begin RF_write_enable = 1; ALU_src = 1; result_select = 3; end//sll
                17'b0010011_001_0000000: begin RF_write_enable = 1; I = 1; result_select = 3; end//slli
                17'b0110011_010_0000000: begin RF_write_enable = 1; ALU_src = 1; result_select = 2; sub = 1; lt = 1; end//slt
                17'b0010011_010_???????: begin RF_write_enable = 1; I = 1; result_select = 2; sub = 1; lt = 1; end//slti
                17'b0110011_011_0000000: begin RF_write_enable = 1; ALU_src = 1; result_select = 2; sub = 1; ltu = 1; end//sltu
                17'b0010011_011_???????: begin RF_write_enable = 1; I = 1; result_select = 2; sub = 1; ltu = 1; end//sltiu
                17'b0110011_100_0000000: begin RF_write_enable = 1; ALU_src = 1; result_select = 1; mask_ctrl = 2; end//xor
                17'b0010011_100_???????: begin RF_write_enable = 1; I = 1; result_select = 1; mask_ctrl = 2; end//xori
                17'b0110011_101_0000000: begin RF_write_enable = 1; ALU_src = 1; result_select = 3; is_right_shift = 1; end//srl
                17'b0010011_101_0000000: begin RF_write_enable = 1; I = 1; result_select = 3; is_right_shift = 1; end//srli
                17'b0110011_101_0100000: begin RF_write_enable = 1; ALU_src = 1; result_select = 3; is_right_shift = 1; is_arithmetic_shift = 1; end//sra
                17'b0010011_101_0100000: begin RF_write_enable = 1; I = 1; result_select = 3; is_right_shift = 1; is_arithmetic_shift = 1; end//srai
                17'b0110011_110_0000000: begin RF_write_enable = 1; ALU_src = 1; result_select = 1; mask_ctrl = 1; end//or
                17'b0010011_110_???????: begin RF_write_enable = 1; I = 1; result_select = 1; mask_ctrl = 1; end//ori
                17'b0110011_111_0000000: begin RF_write_enable = 1; ALU_src = 1; result_select = 1; mask_ctrl = 0; end//and
                17'b0010011_111_???????: begin RF_write_enable = 1; I = 1; result_select = 1; mask_ctrl = 0; end//andi

                //Branches
                17'b1100011_000_???????: begin B = 1; PC_select = 3; sub = 1; eq = 1; end//beq
                17'b1100011_001_???????: begin B = 1; PC_select = 3; sub = 1; eq = 1; negate = 1; end//bne
                17'b1100011_100_???????: begin B = 1; PC_select = 3; sub = 1; lt = 1; end//blt
                17'b1100011_101_???????: begin B = 1; PC_select = 3; sub = 1; lt = 1; negate = 1; end//bge
                17'b1100011_110_???????: begin B = 1; PC_select = 3; sub = 1; ltu = 1; end //bltu
                17'b1100011_111_???????: begin B = 1; PC_select = 3; sub = 1; ltu = 1; negate = 1; end//bgeu

                //Oddball U and J-type instructions
                17'b0010111_???_???????: begin RF_write_enable = 1; U = 1; result_select = 7; end//auipc
                17'b0110111_???_???????: begin RF_write_enable = 1; U = 1; result_select = 4; end//lui
                17'b1100111_000_???????: begin RF_write_enable = 1; I = 1; result_select = 6; PC_select = 2; end//jalr
                17'b1101111_???_???????: begin RF_write_enable = 1; J = 1; result_select = 6; PC_select = 1; end//jal

                //System instructions
                17'b0001111_001_0000000: begin end //fence.i
                17'b1110011_000_???????: begin UNDEFINED_SYSTEM_INSTRUCTION = 1; PC_increment = 0; end //ecall and ebreak

                default: begin INVALID_INSTRUCTION = 1; PC_increment = 0; end //Invalid instruction halts the processor
            endcase

        end
    end
endmodule
