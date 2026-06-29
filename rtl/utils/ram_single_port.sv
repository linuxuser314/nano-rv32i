//Single-ported RAM.
//It is 32-bit word aligned but byte-addressed for simplicity (does not support misaligned words).
`default_nettype none

module ram_single_port #(
             parameter int SIZE,
             parameter string FILE_PATH
            )
            (input logic clk,
            ram_bus_if.slave bus);
    logic[31:0] ram[SIZE];
    initial begin
        for (int i = 0; i < SIZE; i++) ram[i] = 32'b0;
        $readmemh(FILE_PATH, ram);
    end

    always_ff @(posedge clk) begin
        if(bus.read_enable) begin
            bus.read_data <= ram[bus.address[31:2]];
        end
        else bus.read_data <= 32'b0;

        if(bus.write_enable) begin
            if(bus.write_enable_control[0]) ram[bus.address[31:2]][7:0]   <= bus.write_data[7:0];
            if(bus.write_enable_control[1]) ram[bus.address[31:2]][15:8]  <= bus.write_data[15:8];
            if(bus.write_enable_control[2]) ram[bus.address[31:2]][23:16] <= bus.write_data[23:16];
            if(bus.write_enable_control[3]) ram[bus.address[31:2]][31:24] <= bus.write_data[31:24];
        end
    end
endmodule
