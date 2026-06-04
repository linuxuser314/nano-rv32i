//Instantiates a 32-bit RISC-V Register File.
//It has two read ports, one write port, a write enable, a clock signal, and a reset.
//Writes are only comitted on the positive edge of the clock.
//x0 is hardwired to 0.
//Based on example 5.8 in Harris & Harris Digital Design and Computer Architecture.
//The reset signal has priority over writes, so resetting will clear the register file even if it is actively writing data.

`default_nettype none
module register_file(input  logic clk, reset, write_enable,
                     input  logic[4 :0] a1, a2, a3,
                     input  logic[31:0] wd3,
                     output logic[31:0] rd1, rd2
                    );
    logic[31:0] rf[32];

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            // We use a local loop integer to clear each element individually
            for (int i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'b0;
            end
        end else if (write_enable) begin
            rf[a3] <= wd3;
        end
    end

    assign rd1 = (a1 == 0) ? 0 : rf[a1];
    assign rd2 = (a2 == 0) ? 0 : rf[a2];

endmodule
