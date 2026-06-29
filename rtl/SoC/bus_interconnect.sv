`default_nettype none


module bus_interconnect(
                        input logic clk, reset, //Currently unused, may need in future.

                        ram_bus_if.slave core0_fetch_bus,
                        output logic FETCH_FAULT,

                        ram_bus_if.slave core0_data_bus,
                        output logic DATA_FAULT,

                        ram_bus_if.master boot_rom_bus,
                        ram_bus_if.master payload_rom_bus,

                        ram_bus_if.master mmio_bus,
                        input logic MMIO_FAULT,

                        ram_bus_if.master system_ram0_bus_A,
                        ram_bus_if.master system_ram0_bus_B);

    logic[1:0] data_select, fetch_select;

    always_comb begin
        boot_rom_bus.address = core0_fetch_bus.address;
        boot_rom_bus.read_enable = 1'b0;
        boot_rom_bus.write_data = 32'b0;
        boot_rom_bus.write_enable = 1'b0;
        boot_rom_bus.write_enable_control = 4'b0;

        payload_rom_bus.address = core0_data_bus.address;
        payload_rom_bus.read_enable = 1'b0;
        payload_rom_bus.write_data = 32'b0;
        payload_rom_bus.write_enable = 1'b0;
        payload_rom_bus.write_enable_control = 4'b0;

        mmio_bus.address = core0_data_bus.address;
        mmio_bus.read_enable = 1'b0;
        mmio_bus.write_data = 32'b0;
        mmio_bus.write_enable = 1'b0;
        mmio_bus.write_enable_control = 4'b0;

        system_ram0_bus_A.address = core0_fetch_bus.address;
        system_ram0_bus_A.read_enable = 1'b0;
        system_ram0_bus_A.write_data = 32'b0;
        system_ram0_bus_A.write_enable = 1'b0;
        system_ram0_bus_A.write_enable_control = 4'b0;

        system_ram0_bus_B.address = core0_data_bus.address;
        system_ram0_bus_B.read_enable = 1'b0;
        system_ram0_bus_B.write_data = 32'b0;
        system_ram0_bus_B.write_enable = 1'b0;
        system_ram0_bus_B.write_enable_control = 4'b0;

        DATA_FAULT = 1'b0;
        FETCH_FAULT = 1'b0;

        fetch_select = 2'b0;
        data_select = 2'b0;

        //Data component
        case(core0_data_bus.address[31:30])
            0: begin
                //0x0000_0000 to 0x0000_07FF: ROM (x)
                DATA_FAULT = 1;//Region 0 does not have rw privleges.
            end
            1: begin
                //0x4000_0000 to 0x4000_07FF: Payload ROM(r)
                if(core0_data_bus.write_enable) begin
                    DATA_FAULT = 1;//Region 1 does not have w privleges.
                end
                else if(core0_data_bus.read_enable) begin
                    if(core0_data_bus.address >= 32'h4000_0000 && core0_data_bus.address <= 32'h4000_07FF) begin
                        data_select = 2'b01;
                    end
                    else DATA_FAULT = 1;
                end
            end
            2: begin
                //0x8000_0000 to 0x8000_07FF: MMIO (rw, volatile attribute in C/C++ mandatory)

                if(core0_data_bus.address >= 32'h8000_0000 && core0_data_bus.address <=32'h8000_07FF) begin
                    if(core0_data_bus.read_enable) begin
                        data_select = 2'b10;
                    end
                    if(core0_data_bus.write_enable) begin
                        mmio_bus.write_enable = 1'b1;
                        mmio_bus.write_enable_control = 4'b0;//MMIO does not support strobed writes yet!
                        mmio_bus.write_data = core0_data_bus.write_data;
                    end
                end
                else DATA_FAULT = 1;
            end
            3: begin
                //0xC000_0000 to 0xC000_07FF: RAM (rwx)
                if(core0_data_bus.address >= 32'hC000_0000 && core0_data_bus.address <= 32'hC000_07FF) begin
                   if(core0_data_bus.read_enable) begin
                    data_select = 2'b11;
                   end
                   if(core0_data_bus.write_enable) begin
                    system_ram0_bus_B.write_enable = 1'b1;
                    system_ram0_bus_B.write_enable_control = core0_data_bus.write_enable_control;
                    system_ram0_bus_B.write_data = core0_data_bus.write_data;
                   end
                end
                else DATA_FAULT = 1;
            end
            default: DATA_FAULT = 1;
        endcase

        //Fetch component

        case(core0_fetch_bus.address[31:30])
            0: begin
                //0x0000_0000 to 0x0000_07FF: ROM (x)
                if(core0_fetch_bus.address >= 32'h0000_0000 && core0_fetch_bus.address <= 32'h0000_07FF && core0_fetch_bus.read_enable) begin
                    fetch_select = 2'b01;
                end
                else FETCH_FAULT = 1;
            end
            1: begin
                //0x4000_0000 to 0x4000_07FF: Payload ROM(r)
                FETCH_FAULT = 1;//Payload ROM only has r privleges.
            end
            2: begin
                //0x8000_0000 to 0x8000_07FF: MMIO (rw, volatile attribute in C/C++ mandatory)
                FETCH_FAULT = 1;//MMIO only has rw privleges
            end
            3: begin
                //0xC000_0000 to 0xC000_07FF: RAM (rwx)
                if(core0_fetch_bus.address >= 32'hC000_0000 && core0_fetch_bus.address <= 32'hC000_07FF && core0_fetch_bus.read_enable) begin
                    fetch_select = 2'b10;
                end
                else FETCH_FAULT = 1;
            end
            default: FETCH_FAULT = 1;
        endcase
        case(fetch_select)
            2'b00: begin end//do nothing
            2'b01: begin
                core0_fetch_bus.read_data = boot_rom_bus.read_data;
                boot_rom_bus.read_enable = 1'b1;
            end
            2'b10: begin
                core0_fetch_bus.read_data = system_ram0_bus_A.read_data;
                system_ram0_bus_A.read_enable = 1'b1;
            end
            default: core0_fetch_bus.read_data = 32'b0;
        endcase
        case(data_select)
            2'b00: begin end//do nothing
            2'b01: begin
                core0_data_bus.read_data = payload_rom_bus.read_data;
                payload_rom_bus.read_enable = 1'b1;
            end
            2'b10: begin
                core0_data_bus.read_data = mmio_bus.read_data;
                mmio_bus.read_enable = 1'b1;
            end
            2'b11: begin
                core0_data_bus.read_data = system_ram0_bus_B.read_data;
                system_ram0_bus_B.read_enable = 1'b1;
            end
            default: core0_data_bus.read_data = 32'b0;
        endcase
        DATA_FAULT = DATA_FAULT || MMIO_FAULT;
    end

endmodule
