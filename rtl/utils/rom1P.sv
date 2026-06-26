//Single-ported Read Only Memory.
//It is initialized to zero and overwritten by whatever is at FILE_PATH (defaults to software/ROM.hex).
//It is 32-bit word aligned but byte-addressed for simplicity (does not support misaligned words).
`default_nettype none

module rom1P #(
             parameter int SIZE = 576,
             parameter string FILE_PATH = "/workspaces/nano-rv32i/software/boot_rom.hex"
            )
            (input  logic[31:0] address,
             input  logic       clk, read_enable,
             output logic[31:0] result);
    logic[31:0] rom[(SIZE / 4)];
    initial begin
        for (int i = 0; i < (SIZE / 4); i++) rom[i] = 32'b0;
        $readmemh(FILE_PATH, rom);
    end

    always_ff @(posedge clk) begin
        if(read_enable) begin
            result <= rom[address[31:2]];
        end
        else result <= 32'b0;
    end
endmodule
