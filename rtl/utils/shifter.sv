//This module is a barrell shifter designed to support both left and right logical and arithmetic shifting.
//I will probably add a rotation mode to this module when I add the RISC-V B extension.
//This module should have a 7-LUT propogation delay (5 stages + 2 reversals) and use 225 LUTs (7 stages * LUTs per stage + 1 fill bit calculator)
//It does NOT support left arithmetic shifting and requires the reverse32.sv file to function
`default_nettype none
module shifter(input logic[31:0] data_in,
               input logic[4:0] shamt,
               input logic is_right_shift, is_arithmetic_shift,
               output logic[31:0] result);

    logic[31:0] reverse_stage, stage_1, stage_2, stage_3, stage_4, stage_5, bits_reversed_in, bits_reversed_out;
    logic fill_bit;

    //If it is an arithmetic shift, it pulls in the LSB for left shift and the MSB for right shift.
    //fill_bit will be copied into every blank bit during the shift.
    assign fill_bit = is_arithmetic_shift &
                      (~is_right_shift & data_in[0] | is_right_shift & data_in[31]);

    // Instantiate for the initial reversal (Port A)
    reverse32 rev_in_inst (
        .data_in(data_in),
        .data_out(bits_reversed_in)
    );

    // FIX 1: Removed duplicate driver line
    assign reverse_stage = is_right_shift ? bits_reversed_in : data_in;

    // FIX 2: Corrected stage progression to pipe results sequentially forward
    assign stage_1 = shamt[4] ? {reverse_stage[15:0], {16{fill_bit}}} : reverse_stage;
    assign stage_2 = shamt[3] ? {stage_1[23:0],       { 8{fill_bit}}} : stage_1;
    assign stage_3 = shamt[2] ? {stage_2[27:0],       { 4{fill_bit}}} : stage_2;
    assign stage_4 = shamt[1] ? {stage_3[29:0],       { 2{fill_bit}}} : stage_3;
    assign stage_5 = shamt[0] ? {stage_4[30:0],       { 1{fill_bit}}} : stage_4;

    // Instantiate for the final reversal (Port B)
    reverse32 rev_out_inst (
        .data_in(stage_5),
        .data_out(bits_reversed_out)
    );
    assign result = is_right_shift ? bits_reversed_out : stage_5;

endmodule
