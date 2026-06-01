`default_nettype none
module shifter(input logic[31:0] data_in,
               input logic[4:0] shamt,
               input logic is_right_shift, is_arithmetic_shift,
               output logic[31:0] result);
    //This module is a barrell shifter designed to support both left and right logical and arithmetic shifting.
    //I will probably add a rotation mode to this module when I add the RISC-V B extension.

    logic[31:0] reverse_stage, stage_1, stage_2, stage_3, stage_4, stage_5;
    logic fill_bit;

    //If it is an arithmetic shift, it pulls in the LSB for left shift and the MSB for right shift.
    //fill_bit will be copied into every blank bit during the shift.
    assign fill_bit = is_arithmetic_shift &
                      (~is_right_shift & data_in[0] | is_right_shift & data_in[31]);

    //I think this will reverse it... But I could be wrong! I'll do testbenches when I have wifi.
    //Then it shifts each stage left by 16, 8, 4, 2, or 1 bits if the shamt (shift ammount) bits for those ammounts are triggered.
    //Then it reverses it again if it's a right shift.
    assign reverse_stage[31:0]= is_right_shift  ? data_in[0:31] : data_in[31:0];
    assign stage_1 = shamt[4] ? {data_in[15:0], {16{fill_bit}}} : data_in[31:0];
    assign stage_2 = shamt[3] ? {data_in[23:0], { 8{fill_bit}}} : stage_1[31:0];
    assign stage_3 = shamt[2] ? {data_in[27:0], { 4{fill_bit}}} : stage_2[31:0];
    assign stage_4 = shamt[1] ? {data_in[29:0], { 2{fill_bit}}} : stage_3[31:0];
    assign stage_5 = shamt[0] ? {data_in[30:0], { 1{fill_bit}}} : stage_4[31:0];
    assign result      [31:0] = is_right_shift  ? stage_5[0:31] : stage_5[31:0];



endmodule
