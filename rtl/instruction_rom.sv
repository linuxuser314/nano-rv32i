module instruction_rom(
    input  logic[31:0] PC,
    output logic[31:0] instruction
);
    logic[31:0] rom [2048];  // Simple instruction memory

    initial begin
        $readmemh("/workspaces/nano-rv32i/software/firmware.hex", rom);
    end

    // Combinational read (ROM is asynchronous)
    assign instruction = rom[PC[9:2]];  // Word-addressed
endmodule
