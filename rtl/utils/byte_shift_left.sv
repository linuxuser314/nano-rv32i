//This module takes a 4-byte word and shifts it to the left at byte-aligned increments
//Estimated resouce usage: 64 LUTs (32 LUTs/stage x 2 stages), 2-LUT propogation delay
module byte_shift_left(input logic[31:0] data,
                        input logic shift1, shift2,
                        output logic[31:0] result
                        );

    logic[31:0] stage;
    //Shift the result to the left as appropriate and padd with 0s as appropriate.
    assign stage  = shift2 ? {data [15:0], 16'b0}: data [31:0];
    assign result = shift1 ? {stage[23: 0], 8'b0} : stage[31:0];
endmodule
