`default_nettype none

module instruction_rom(
    input  logic[31:0] PC,
    input  logic clk,
    output logic[31:0] instruction
);
    logic[31:0] rom [8];  // Simple instruction memory

    initial begin
        rom[0] = 32'h00000093;
        rom[1] = 32'h40000137;
        rom[2] = 32'h00108093;
        rom[3] = 32'h00112023;
        rom[4] = 32'hFF9FF06F;
        rom[5] = 32'h00000000;
        rom[6] = 32'h00000000;
        rom[7] = 32'h00000000;
    end

    // Combinational read (ROM is asynchronous)
    //assign instruction = rom[PC[9:2]];  // Word-addressed

    //Sequential read (for proper testing as if this were my actual memory module)
    always_ff @(posedge clk) begin
        instruction <= rom[PC[4:2]];
    end
endmodule
