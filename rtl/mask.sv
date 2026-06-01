`default_nettype none;
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
