//Instantiates a 32-bit RISC-V Register File.
//It has two read ports, one write port, a write enable, a clock signal, and a reset.
//x0 is hardwired to 0.
//Based on example 5.8 in Harris & Harris Digital Design and Computer Architecture.

`default_nettype none
module register_file(input  logic clk, reset, write_enable,
                     input  logic[5 :0] a1, a2, a3,
                     input  logic[31:0] wd3,
                     output logic[31:0] rd1, rd2
                    );
    logic[31:0] rf[32];

    always_ff @(posedge clk, posedge reset) begin
        if(write_enable) rf[a3] <= wd3;
        if(reset) rf[31:0] <= 32'b0;//This may or may not work.
    end

    assign rd1 = (a1 == 0) ? 0 : rf[a1];
    assign rd2 = (a2 == 0) ? 0 : rf[a2];

endmodule
