//Performs a mask (and, or, or xor) on two 32-bit values and returns the result.
// a ctrl line of 0 is and, 1 is or, 2 is xor, and anything else outputs 0.
//This module should have a propogation delay of 1 LUT and use 32 LUTs total.

`default_nettype none
module mask(input logic[31:0] a, b,
            input logic[1:0] ctrl,
            output logic[31:0] result);
    always_comb begin
        case(ctrl)
            0: result = a & b;
            1: result = a | b;
            2: result = a ^ b;
            default result = 0;
        endcase
    end
endmodule
