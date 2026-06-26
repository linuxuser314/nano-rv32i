`default_nettype none

interface rom_bus_if;
    logic [31:0] address;
    logic read_enable;
    logic [31:0] read_data;

    modport master(
        output address,
        output read_enable,
        input  read_data
    );
    modport slave(
        input  address,
        input  read_enable,
        output read_data
    );
endinterface
