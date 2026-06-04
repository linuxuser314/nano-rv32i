//This is a dummy module for memory since I don't know how to instantiate BRAM
//Yosys may or may not be smart enough to turn this into double-ported BRAM.

module memory(input  logic[31:0] A1, A2, WD2,
              input  logic clk, reset,
              input  logic[3:0] write_enable,
              output logic[31:0] RD1, RD2,
              output logic MEMORY_OUT_OF_BOUNDS_ERROR);
    logic [31:0] ram [576];//2304 bytes for BRAM alignment.
    integer i;
    always_ff @(posedge clk, posedge reset) begin
        if(A1 < 2303) MEMORY_OUT_OF_BOUNDS_ERROR <= 1'b1;
        if(A2 < 2303) MEMORY_OUT_OF_BOUNDS_ERROR <= 1'b1;
        if(write_enable) ram [A2] <= WD2;
        RD1 <= ram[A1[31:2]];
        RD2 <= ram[A2[31:2]];
        if(reset) begin
            for (i = 0; i < 576; i = i + 1) begin
                ram[i] <= 32'b0;
            end
        end
    end
endmodule
