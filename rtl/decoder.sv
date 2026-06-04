//Decoder dummy module
`default_nettype none

module decoder(input  logic[31:0] instruction,
               input  logic        clk, reset,
                                   MEMORY_MISALIGNED_ERROR,
                                   INSTRUCTION_MISALIGNED_ERROR,
                                   MEMORY_OUT_OF_BOUNDS_ERROR,
                output logic I, S, B, U, J, is_byte, is_half, is_unsigned, is_store,
                             eq, lt, ltu, negate, sub, PC_increment, RF_write_enable,
                             is_right_shift, is_arithmetic_shift, ALU_src,
                output logic[1:0] mask_ctrl, PC_select,
                output logic[2:0] result_select
                );
    logic[16:0] instruction_data;
    assign instruction_data = {instruction[6:0], instruction[14:12], instruction[31:25]};
    always_comb begin
        casez(instruction_data)
        //Format opcode_funct3_funct7
            17'b0110011_000_0100000: ALU_src = 1; sub = 1; result_select = 3;//sub
            17'b0110011_000_0000000: ALU_src = 1; result_select = 3;//add
            17'b0010011_000_???????: I = 1; result_select = 3;//addi
            17'b0110011_001_0000000: ALU_src = 1; result_select = 3;//sll
            17'b0010011_001_0000000: I = 1; result_select = 3;//slli
            17'b0110011_010_0000000: ALU_src = 1; result_select = 2; sub = 1; lt = 1;//slt
            17'b0010011_010_???????: I = 1; result_select = 2; sub = 1; lt = 1;//slti
            17'b0110011_011_0000000: ALU_src = 1; result_select = 2; sub = 1; ltu = 1;//sltu
            17'b0010011_011_???????: I = 1; result_select = 2; sub = 1; ltu = 1;//sltiu
            17'b0110011_100_0000000: ALU_src = 1; result_select = 1; mask_ctrl = 2;//xor
            17'b0010011_100_???????: I = 1; result_select = 1; sub = 1; mask_ctrl = 2;//xori
            17'b0110011_101_0000000: ALU_src = 1; result_select = 3; is_right_shift = 1;//srl
            17'b0010011_101_0000000: I = 1; result_select = 3; is_right_shift = 1;//srli
            17'b0110011_110_0000000: ALU_src = 1; result_select = 3; is_right_shift = 1; is_arithmetic_shift = 1;//sra
            17'b0010011_110_0000000: I = 1; result_select = 3; is_right_shift = 1; is_arithmetic_shift = 1;//srai
            17'b0110011_110_0000000: ALU_src = 1; result_select = 1; mask_ctrl = 2;//or
            17'b0010011_110_???????: I = 1; result_select = 1; sub = 1; mask_ctrl = 2;//ori
            17'b0110011_111_0000000: ALU_src = 1; result_select = 1; mask_ctrl = 2;//and
            17'b0010011_111_???????: I = 1; result_select = 1; sub = 1; mask_ctrl = 2;//andi
            //Not done with these...
        endcase
    end
endmodule
