`default_nettype none

module fetch_unit(ram_bus_if.master bus,
                  output logic[31:0] instruction,
                  input logic[31:0] PC,
                  output logic FETCH_MISALIGNED
                  );

    assign bus.read_enable = 1'b1;
    assign bus.address = {PC[31:2], 2'b0};
    assign instruction = bus.read_data;
    assign FETCH_MISALIGNED = PC[0] | PC[1];

    //Unused signals
    assign bus.write_enable = 1'b0;
    assign bus.write_enable_control = 4'b0;
    assign bus.write_data = 32'b0;
endmodule
