//This is the memory module. It's a dual-ported memory for simultaneous instruction fetching and load/stores.
//It is currently read-first, which I will need to change (or add external forwarding logic) to support back-to-back store load.
//I currently have 2304 bytes of memory.
/*module memory(input  logic[31:0] A1, A2, WD2,
              input  logic clk,
              input  logic[3:0] write_enable,
              output logic[31:0] RD1, RD2,
              output logic MEMORY_OUT_OF_BOUNDS_ERROR);
    logic [31:0] ram [576];//2304 bytes for BRAM alignment.
    logic [31:0] tohost;
    initial begin
        for (int i = 0; i < 576; i++) ram[i] = 32'b0;
        $readmemh("/workspaces/nano-rv32i/software/firmware.hex", ram);
    end


    always_ff @(posedge clk) begin
        if(A2[31:2] < 30'd576) begin
            if(write_enable[0]) ram[A2[31:2]][7:0]   <= WD2[7:0];
            if(write_enable[1]) ram[A2[31:2]][15:8]  <= WD2[15:8];
            if(write_enable[2]) ram[A2[31:2]][23:16] <= WD2[23:16];
            if(write_enable[3]) ram[A2[31:2]][31:24] <= WD2[31:24];
            RD2 <= ram[A2[31:2]];
        end
        else if(A2 == 32'h40000000) begin
            if(write_enable[0] & write_enable[1] & write_enable[2] & write_enable[3]) tohost <= WD2;
        end
        else begin
            MEMORY_OUT_OF_BOUNDS_ERROR = 1'b1;
        end

        if(A2[31:2] < 30'd576) begin
            RD1 <= ram[A1[31:2]];
        end
        else MEMORY_OUT_OF_BOUNDS_ERROR = 1'b1;

    end

endmodule
*/
//Patched AI generated module
`default_nettype none

module memory(input  logic[31:0] A1, A2, WD2,
              input  logic clk,
              input  logic[3:0] write_enable,
              output logic[31:0] RD1, RD2,
              output logic[31:0] tohost, // <-- Exported so testbench can watch it!
              output logic MEMORY_OUT_OF_BOUNDS_ERROR);

    logic [31:0] ram [576]; // 2304 bytes

    initial begin
        for (int i = 0; i < 576; i++) ram[i] = 32'b0;
        $readmemh("/workspaces/nano-rv32i/software/firmware.hex", ram);
        tohost = 32'b0; // Initialize tohost to 0
    end

    always_ff @(posedge clk) begin
        // ==========================================
        // PORT 1: Instruction Fetch (Strictly A1)
        // ==========================================
        if (A1[31:2] < 30'd576) begin
            RD1 <= ram[A1[31:2]];
        end else begin
            RD1 <= 32'b0;
        end

        // ==========================================
        // PORT 2: Data Memory & MMIO (Strictly A2)
        // ==========================================
        if (A2[31:2] < 30'd576) begin
            // Normal RAM Write
            if(write_enable[0]) ram[A2[31:2]][7:0]   <= WD2[7:0];
            if(write_enable[1]) ram[A2[31:2]][15:8]  <= WD2[15:8];
            if(write_enable[2]) ram[A2[31:2]][23:16] <= WD2[23:16];
            if(write_enable[3]) ram[A2[31:2]][31:24] <= WD2[31:24];

            // Normal RAM Read
            RD2 <= ram[A2[31:2]];
        end 
        else if (A2 == 32'h40000000) begin
            // MMIO: Write to tohost
            // If any write_enable bit is high, capture the data
            if (|write_enable) tohost <= WD2;

            RD2 <= 32'b0; // Reading MMIO returns 0 for now
        end
        else begin
            RD2 <= 32'b0;
        end
    end

    // ==========================================
    // COMBINATIONAL ERROR LOGIC
    // ==========================================
    // This evaluates instantly, telling the decoder to freeze the PC immediately.
    // It ignores A2 if A2 is targeting the 0x40000000 MMIO address.
    assign MEMORY_OUT_OF_BOUNDS_ERROR = (A1[31:2] >= 30'd576) |
                                       ((A2[31:2] >= 30'd576) & (A2 != 32'h40000000));

endmodule
