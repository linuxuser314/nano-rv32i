//This module takes a 4-byte word and shifts it to the right one byte at a time.
//Estimated resouce usage: 64 LUTs (32 LUTs/stage x 2 stages), 2-LUT propogation delay
module byte_shift_right(input logic[31:0] data,
                        input logic shift1, shift2, fill_bit,
                        output logic[31:0] result
                        );

    logic[31:0] stage;
    //Shift the result to the right as appropriate and padd with fill_bits as appropriate.
    assign stage  = shift2 ? {{16{fill_bit}}, data [31:16]} : data [31:0];
    assign result = shift1 ? {{ 8{fill_bit}}, stage[31: 8]} : stage[31:0];
endmodule
