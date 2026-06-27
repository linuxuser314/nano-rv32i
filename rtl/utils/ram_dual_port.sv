//Dual-ported RAM.
//It is 32-bit word aligned but byte-addressed for simplicity (does not support misaligned words).
`default_nettype none

module ram_dual_port #(
             parameter int SIZE
             //parameter string FILE_PATH Commented out because loading default values to dual-ported BRAM is incredibly finnicky on Apicula
            )
            (input clk,
            ram_bus_if.slave bus_A,
            ram_bus_if.slave bus_B);
    logic[31:0] ram[SIZE];
    initial begin
        for (int i = 0; i < SIZE; i++) ram[i] = 32'b0;
        //$readmemh(FILE_PATH, ram);
    end
    //Port A
    always_ff @(posedge clk) begin
        if(bus_A.read_enable) begin
            bus_A.result <= ram[bus_A.address[31:2]];
        end
        else bus_A.result <= 32'b0;

        if(bus_A.write_enable) begin
            if(bus_A.write_enable_control[0]) ram[bus_A.address[31:2]][7:0]   <= bus_A.write_data[7:0];
            if(bus_A.write_enable_control[1]) ram[bus_A.address[31:2]][15:8]  <= bus_A.write_data[15:8];
            if(bus_A.write_enable_control[2]) ram[bus_A.address[31:2]][23:16] <= bus_A.write_data[23:16];
            if(bus_A.write_enable_control[3]) ram[bus_A.address[31:2]][31:24] <= bus_A.write_data[31:24];
        end
    end
    //Port B
    always_ff @(posedge clk) begin
        if(bus_B.read_enable) begin
            bus_B.result <= ram[bus_B.address[31:2]];
        end
        else bus_B.result <= 32'b0;

        if(bus_B.write_enable) begin
            if(bus_B.write_enable_control[0]) ram[bus_B.address[31:2]][7:0]   <= bus_B.write_data[7:0];
            if(bus_B.write_enable_control[1]) ram[bus_B.address[31:2]][15:8]  <= bus_B.write_data[15:8];
            if(bus_B.write_enable_control[2]) ram[bus_B.address[31:2]][23:16] <= bus_B.write_data[23:16];
            if(bus_B.write_enable_control[3]) ram[bus_B.address[31:2]][31:24] <= bus_B.write_data[31:24];
        end
    end
endmodule
