`default_nettype none

//Sits inside the interconnect bus.
//This converts a RAM module's bus to a ROM bus so a RAM module can only be read from
//and Yosys will demote it to a ROM module without having an extra module type.

module rom_to_ram_adapter(rom_bus_if.slave rom,
                          ram_bus_if.master ram);
    assign ram.address = rom.address;
    assign ram.read_enable = rom.read_enable;
    assign rom.read_data = ram.read_data;

    //To prevent floating values and so Yosys tunes it out
    assign ram.write_data = 32'b0;
    assign ram.write_enable = 1'b0;
    assign ram.write_enable_control = 4'b0;
endmodule
