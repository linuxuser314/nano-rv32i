//This is a dummy module for memory since I don't know how to instantiate BRAM
//Yosys may or may not be smart enough to turn this into double-ported BRAM.

module memory(input  logic[31:0] A1, A2, WD2,
              input  logic clk,
              input  logic[3:0] write_enable,
              output logic[31:0] RD1, RD2,
              output logic MEMORY_OUT_OF_BOUNDS_ERROR);
    logic [31:0] ram [576];//2304 bytes for BRAM alignment.
    initial begin
        for (int i = 0; i < 576; i++) ram[i] = 32'b0;
        $readmemh("/workspaces/nano-rv32i/software/firmware.hex", ram);
    end

    // Safe address decoding to protect against the startup 'x' loop
    logic [29:0] safe_a1, safe_a2;
    assign safe_a1 = ($isunknown(A1[31:2])) ? 30'd0 : A1[31:2];
    assign safe_a2 = ($isunknown(A2[31:2])) ? 30'd0 : A2[31:2];

    always_ff @(posedge clk) begin
        if(write_enable) ram[safe_a2] <= WD2;//NEEDS TO BE FIXED!
        RD1 <= ram[safe_a1];
        RD2 <= ram[safe_a2];

    end
    //assign MEMORY_OUT_OF_BOUNDS_ERROR = (A1[31:2] >= 30'd576) || (A2[31:2] >= 30'd576);
    assign MEMORY_OUT_OF_BOUNDS_ERROR = 1'b0;
endmodule
