
`default_nettype none

module adder(input  logic[31:0] a, b,
             input  logic       cin,
             output logic[31:0] result,
             output logic       cout
             );
    //33-bit intermediate for carry-out checking. This is not an ideal setup and I'm not sure how Yosys will optimize it but it should be functional.
    logic[32:0] intermediate;
    assign intermediate = {1'b0, a} + {1'b0, b} + {32'b0, cin};
    assign result = intermediate[31:0];
    assign cout = intermediate[32];

endmodule
