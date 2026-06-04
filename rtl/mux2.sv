module mux2(input  logic[31:0] in0, in1,
            input  logic       select,
            output logic[31:0] result
        );
        assign result = select ? in1 : in0;
endmodule
