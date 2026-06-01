`default_nettype none

module mux8(input  logic[31:0] in0, in1, in2, in3, in4, in5, in6, in7,
            input  logic[2 :0] select,
            output logic[31:0] out);
    always_comb begin
        case(select)
            0: out = in0;
            1: out = in1;
            2: out = in2;
            3: out = in3;
            4: out = in4;
            5: out = in5;
            6: out = in6;
            7: out = in7;
            default: out = 32'b0;
        endcase
    end

endmodule
