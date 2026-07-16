//This is the top SoC module.


/*
0x0000_0000 to 0x0000_07FF: ROM (x)
0x8000_0000 to 0x8000_07FF: MMIO (rw, volatile tag in C/C++ mandatory)
0xC000_0000 to 0xC000_07FF: RAM (rwx)
Memory regions expanded to 16KB, did not update map yet!
*/

`default_nettype none

module soc_top(input  logic      clk_27MHz, reset_button,
               `ifdef VERILATOR
                   output logic[31:0] tohost,
                `endif
               output logic[5:0] led_strip6

               );
    localparam int BOOT_ROM_SIZE = 4096;
    localparam int SYSTEM_RAM0_SIZE = 4096;
    localparam string bootloader_hex_path = "/workspaces/nano-rv32i/build/target/bootloader.hex";
    localparam string sim_payload_hex_path = "/workspaces/nano-rv32i/build/target/sim_payload.hex";


    //Leave them simple for now.
    logic sys_clk, sys_reset;
    assign sys_clk = clk_27MHz;
    assign sys_reset = reset_button;

    logic MMIO_FAULT;
    logic core0_FETCH_FAULT, core0_DATA_FAULT;

    ram_bus_if core0_fetch_bus(); //Master 0
    ram_bus_if core0_data_bus(); //Master 1

    ram_bus_if boot_rom_bus(); //Slave 0
    ram_bus_if mmio_bus(); //Slave 2

    ram_bus_if system_ram0_bus_A(); // Slave 3 (FETCH)
    ram_bus_if system_ram0_bus_B(); // Slave 4 (DATA)


    //Master 0/1 (core0_fetch, core0_data)
    rv32i_core core0(

        //Instruction fetching
        .fetch_bus(core0_fetch_bus),
        .FETCH_FAULT(core0_FETCH_FAULT),

        //Data reading/writing
        .DATA_FAULT(core0_DATA_FAULT),
        .data_bus(core0_data_bus),

        .clk(sys_clk), .reset(sys_reset)
    );

    //Master-slave bus interconnect
    bus_interconnect #(
        .BOOT_ROM_SIZE(BOOT_ROM_SIZE),
        .SYSTEM_RAM0_SIZE(SYSTEM_RAM0_SIZE)
    ) master_bus(
        .clk(sys_clk), .reset(sys_reset),
        //Master 0 (core0 fetch)
        .core0_fetch_bus(core0_fetch_bus),
        .FETCH_FAULT(core0_FETCH_FAULT),

        //Master 1 (core0 data)
        .core0_data_bus(core0_data_bus),
        .DATA_FAULT(core0_DATA_FAULT),

        //Slave 0 (boot_rom)
        .boot_rom_bus(boot_rom_bus),

        //Slave 2 (mmio_controller)
        .mmio_bus(mmio_bus),
        .MMIO_FAULT(MMIO_FAULT),

        //Slave 3 (system_ram0_A)
        .system_ram0_bus_A(system_ram0_bus_A),

        //Slave 4 (system_ram0_B)
        .system_ram0_bus_B(system_ram0_bus_B)

    );

    //Slave 0 (boot_rom)
    ram_single_port #(
        .FILE_PATH(bootloader_hex_path),
        .SIZE(BOOT_ROM_SIZE)
    ) boot_rom(
        .clk(sys_clk),
        .bus(boot_rom_bus)
    );

    //Slave 2 (mmio_controller)
    mmio mmio_controller(
        .clk(sys_clk),
        .reset(sys_reset),
        .bus(mmio_bus),
        .led_strip6(led_strip6),
        `ifdef VERILATOR
            .tohost(tohost),
        `endif
        .MMIO_FAULT(MMIO_FAULT)
    );

    //Slave 3/4 (system_ram0)
    ram_dual_port #(
        .SIZE(SYSTEM_RAM0_SIZE),
       .FILE_PATH(sim_payload_hex_path)
    ) system_ram0(
        .clk(sys_clk),

        //Slave3 (system_ram0_A)
        .bus_A(system_ram0_bus_A),

        //Slave4 (system_ram0_B)
        .bus_B(system_ram0_bus_B)
    );
    
endmodule
