`default_nettype none;
module mask(input logic[31:0] a, b,
            input logic[1:0] ctrl,
            output logic[31:0] reult);
    always_comb begin
        unique case(ctrl)
            0: result = a & b;
            1: result = a | b;
            2: result = a ^ b;
            3: result = 0;
        endcase
    end
endmodule
