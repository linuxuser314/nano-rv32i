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
                     output logic[31:0] rd1, rd2,
                     output logic[31:0] x0, x1, x2, x3, x4, x5, x6, x7, x8,
                                        x9, x10, x11, x12, x13, x14, x15, x16,
                                        x17, x18, x19, x20, x21, x22, x23, x24,
                                        x25, x26, x27, x28, x29, x30, x31
                    );
    logic[31:0] rf[32];

    always_ff @(posedge clk) begin
        if (/*reset*/ 1'b0) begin
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
    //Register file outputs for debugging in GTKWave
    assign x0 = rf[0];
    assign x1 = rf[1];
    assign x2 = rf[2];
    assign x3 = rf[3];
    assign x4 = rf[4];
    assign x5 = rf[5];
    assign x6 = rf[6];
    assign x7 = rf[7];
    assign x8 = rf[8];
    assign x9 = rf[9];
    assign x10 = rf[10];
    assign x11 = rf[11];
    assign x12 = rf[12];
    assign x13 = rf[13];
    assign x14 = rf[14];
    assign x15 = rf[15];
    assign x16 = rf[16];
    assign x17 = rf[17];
    assign x18 = rf[18];
    assign x19 = rf[19];
    assign x20 = rf[20];
    assign x21 = rf[21];
    assign x22 = rf[22];
    assign x23 = rf[23];
    assign x24 = rf[24];
    assign x25 = rf[25];
    assign x26 = rf[26];
    assign x27 = rf[27];
    assign x28 = rf[28];
    assign x29 = rf[29];
    assign x30 = rf[30];
    assign x31 = rf[31];

endmodule
