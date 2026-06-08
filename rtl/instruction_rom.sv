module instruction_rom(
    input  logic[31:0] PC,
    input  logic clk,
    output logic[31:0] instruction
);
    logic[31:0] rom [2048];  // Simple instruction memory

    initial begin
        for (int i = 0; i < 2048; i++) rom[i] = 32'b0;
        $readmemh("/workspaces/nano-rv32i/software/firmware.hex", rom);
    end

    // Combinational read (ROM is asynchronous)
    //assign instruction = rom[PC[9:2]];  // Word-addressed

    //Sequential read (for proper testing as if this were my actual memory module)
    always_ff @(posedge clk) begin
        instruction <= rom[PC[31:2]];
    end
endmodule
