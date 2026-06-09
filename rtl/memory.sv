//This is the memory module. It's a dual-ported memory for simultaneous instruction fetching and load/stores.
//It is currently read-first, which I will need to change (or add external forwarding logic) to support back-to-back store load.

module memory(input  logic[31:0] A1, A2, WD2,
              input  logic clk,
              input  logic[3:0] write_enable,
              output logic[31:0] RD1, RD2,
              output logic MEMORY_OUT_OF_BOUNDS_ERROR);
    logic [31:0] ram [2048];//2304 bytes for BRAM alignment.
    initial begin
        for (int i = 0; i < 2048; i++) ram[i] = 32'b0;
        $readmemh("/workspaces/nano-rv32i/software/firmware.hex", ram);
    end


    always_ff @(posedge clk) begin
        if(write_enable[0]) ram[A2[31:2]][7:0]   <= WD2[7:0];
        if(write_enable[1]) ram[A2[31:2]][15:8]  <= WD2[15:8];
        if(write_enable[2]) ram[A2[31:2]][23:16] <= WD2[23:16];
        if(write_enable[3]) ram[A2[31:2]][31:24] <= WD2[31:24];
        RD1 <= ram[A1[31:2]];
        RD2 <= ram[A2[31:2]];

    end
    //assign MEMORY_OUT_OF_BOUNDS_ERROR = (A1[31:2] >= 30'd576) || (A2[31:2] >= 30'd576);
    assign MEMORY_OUT_OF_BOUNDS_ERROR = 1'b0;
endmodule
