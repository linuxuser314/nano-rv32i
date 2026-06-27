`default_nettype none

interface ram_bus_if;
    logic [31:0] address;
    logic read_enable;
    logic [31:0] read_data;


    logic        write_enable;
    logic [3:0]  write_enable_control;
    logic [31:0] write_data;

    modport master(
        output address,
        output read_enable,
        input  read_data,

        output write_enable,
        output write_enable_control,
        output write_data
    );
    modport slave(
        input  address,
        input  read_enable,
        output read_data,

        input write_enable,
        input write_enable_control,
        input write_data
    );
endinterface