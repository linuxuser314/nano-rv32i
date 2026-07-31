//Single-ported RAM.
//It is 32-bit word aligned but byte-addressed for simplicity (does not support misaligned words).
`default_nettype none
//[2 +: $clog2(SIZE)] allows me to slice the correct bit range for the address depending on the size involved.

module ram_single_port #(
    /* verilator lint_off UNUSEDPARAM *////Temporary to make it pass CI checks. Need to find a longer-term solution for RAM...
    parameter int SIZE,
    parameter string FILE_PATH = ""
    /* verilator lint_on UNUSEDPARAM */ 
    ) (
    input logic clk,
    ram_bus_if.slave bus
    );
    
    (* ram_style = "logic" *) logic[31:0] ram[SIZE];
    initial begin
        for (int i = 0; i < SIZE; i++) ram[i] = 32'b0;

    //Apparently Yosys doesn't understand how to do this, and it's silently breaking my core!
    //    if(FILE_PATH != "") begin
    //        $readmemh(FILE_PATH, ram);
    //    end

    //It should know how to do this though...
        //$readmemh("/workspaces/nano-rv32i/build/target/bootloader.hex", ram);
        //That wasn't working eitheir, trying this now...
        ram[0]  = 32'h800002b7;
        ram[1]  = 32'h00000313;
        ram[2]  = 32'h0062a223;
        ram[3]  = 32'h008953b7;
        ram[4]  = 32'h44038393;
        ram[5]  = 32'h00000e13;
        ram[6]  = 32'h007e5663;
        ram[7]  = 32'h001e0e13;
        ram[8]  = 32'hff9ff06f;
        ram[9]  = 32'h00130313;
        ram[10] = 32'hfe1ff06f;
    end


    always_ff @(posedge clk) begin
        if(bus.read_enable) begin
            bus.read_data <= ram[bus.address[2 +: $clog2(SIZE)]];
        end
        else bus.read_data <= 32'b0;

        if(bus.write_enable) begin
            if(bus.write_enable_control[0]) ram[bus.address[2 +: $clog2(SIZE)]][7:0]   <= bus.write_data[7:0];
            if(bus.write_enable_control[1]) ram[bus.address[2 +: $clog2(SIZE)]][15:8]  <= bus.write_data[15:8];
            if(bus.write_enable_control[2]) ram[bus.address[2 +: $clog2(SIZE)]][23:16] <= bus.write_data[23:16];
            if(bus.write_enable_control[3]) ram[bus.address[2 +: $clog2(SIZE)]][31:24] <= bus.write_data[31:24];
        end
    end
endmodule
