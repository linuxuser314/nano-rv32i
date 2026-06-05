//This is a dummy module for memory since I don't know how to instantiate BRAM
//Yosys may or may not be smart enough to turn this into double-ported BRAM.

module memory(input  logic[31:0] A1, A2, WD2,
              input  logic clk,
              input  logic[3:0] write_enable,
              output logic[31:0] RD1, RD2,
              output logic MEMORY_OUT_OF_BOUNDS_ERROR);
    logic [31:0] ram [576];//2304 bytes for BRAM alignment.
    initial begin
        // Clears any unmapped memory slots to 0, then loads your program
        for (int i = 0; i < 576; i++) ram[i] = 32'b0;
        $readmemh("../software/riscv-test.hex", ram);
    end
    always_ff @(posedge clk) begin
        if(write_enable) ram[A2[31:2]] <= WD2;
        RD1 <= ram[A1[31:2]];
        RD2 <= ram[A2[31:2]];

    end
    assign MEMORY_OUT_OF_BOUNDS_ERROR = (A1[31:2] >= 30'd576) || (A2[31:2] >= 30'd576);
endmodule
