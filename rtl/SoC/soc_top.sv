//This is the top SoC module.


/*
Memory Map (18Kbit aligned for BRAM):
0x0000_0000 to 0x0000_08FF: ROM (x)
0x4000_0000 to 0x4000_08FF: Payload (r)
0x8000_0000 to 0x8000_08FF: MMIO (rw, volatile tag in C/C++ mandatory)
0xC000_0000 to 0xC000_08FF: RAM (rwx)
*/

`default_nettype none

module soc_top(input  logic      clk_27MHz, reset_button,
               output logic[5:0] led_strip6
               );

    //Leave them simple for now.
    logic sys_clk, sys_reset;
    assign sys_clk = clk_27MHz;
    assign sys_reset = reset_button;
    /*
    //Master0 (core0_fetch) internal signals
    logic[31:0] fetch_addr, fetch_data;
    logic       fetch_enable;
    logic       FETCH_FAULT;

    //Master1 (core0_data) internal signals
    logic[31:0] data_addr, load_data, store_data;
    logic       data_read_enable, data_write_enable;
    logic[3:0]  data_write_enable_control;
    logic DATA_FAULT;

    //Slave0 (boot_rom) internal signals
    logic        boot_rom_read_enable;
    logic [31:0] boot_rom_addr, boot_rom_result;

    //Slave1 (payload_rom) internal signals
    logic        payload_rom_read_enable;
    logic [31:0] payload_rom_addr, payload_rom_result;

    //Slave2 (mmio_controller) internal signals
    logic        mmio_controller_read_enable;
    logic [31:0] mmio_controller_addr, mmio_controller_result;
    logic        mmio_controller_write_enable;
    logic [31:0] mmio_controller_write_data;

    //Slave3 (system_ram0_A) internal signals
    logic        system_ram0_read_enable_A;
    logic [31:0] system_ram0_addr_A, system_ram0_result_A;
    logic        system_ram0_write_enable_A;
    logic [3:0]  system_ram0_write_enable_control_A;
    logic [31:0] system_ram0_write_data_A;

    //Slave4 (system_ram0_B) internal signals
    logic        system_ram0_read_enable_B;
    logic [31:0] system_ram0_addr_B, system_ram0_result_B;
    logic        system_ram0_write_enable_B;
    logic [3:0]  system_ram0_write_enable_control_B;
    logic [31:0] system_ram0_write_data_B;
    */
    rom_bus_if core0_fetch_bus(); //Master 0
    ram_bus_if core0_data_bus(); //Master 1

    rom_bus_if boot_rom_bus(); //Slave 0
    rom_bus_if payload_rom_bus(); // Slave 1
    ram_bus_if mmio_bus(); //Slave 2

    ram_bus_if system_ram0_A(); // Slave 3
    ram_bus_if system_ram0_B(); // Slave 4


    //Master 0/1 (core0_fetch, core0_data)
    rv32i_core core0(
        //Instruction fetching
        .fetch_addr(fetch_addr), .fetch_data(fetch_data),
        .fetch_enable(fetch_enable),
        .FETCH_FAULT(FETCH_FAULT),

        //Data reading/writing
        .data_addr(data_addr), .load_data(load_data), .store_data(store_data),
        .data_read_enable(data_read_enable), .data_write_enable(data_write_enable),
        .data_write_enable_control(data_write_enable_control),
        .DATA_FAULT(DATA_FAULT),

        //Simple passthrough (for now)
        .clk(sys_clk), .reset(sys_reset)
    );

    //Master-slave bus interconnect
    bus_interconnect master_bus(
        //Master 0 (core0 fetch)
        /*
        .fetch_addr(fetch_addr), .fetch_data(fetch_data),
        .fetch_enable(fetch_enable),*/
        .fetch_bus(core0_fetch_bus),
        .FETCH_FAULT(FETCH_FAULT),

        //Master 1 (core0 data)
        /*
        .data_addr(data_addr), .load_data(load_data), .store_data(store_data),
        .data_read_enable(data_read_enable), .data_write_enable(data_write_enable),
        .data_write_enable_control(data_write_enable_control),*/
        .data_bus(core0_data_bus),
        .DATA_FAULT(DATA_FAULT),

        //Slave 0 (boot_rom)
        .boot_rom_read_enable(boot_rom_read_enable),
        .boot_rom_addr(boot_rom_addr),
        .boot_rom_result(boot_rom_result),

        //Slave 1 (payload_rom)
        .payload_rom_read_enable(payload_rom_read_enable),
        .payload_rom_addr(payload_rom_addr),
        .payload_rom_result(payload_rom_result),

        //Slave 2 (mmio_controller)
        .mmio_controller_read_enable(mmio_controller_read_enable),
        .mmio_controller_addr(mmio_controller_addr),
        .mmio_controller_result(mmio_controller_result),
        .mmio_controller_write_enable(mmio_controller_write_enable),
        .mmio_controller_write_data(mmio_controller_write_data),

        //Slave 3 (system_ram0_A)
        .system_ram_read_enable_A(system_ram0_read_enable_A),
        .system_ram_addr_A(system_ram0_addr_A),
        .system_ram_result_A(system_ram0_result_A),
        .system_ram_write_enable_A(system_ram0_write_enable_A),
        .system_ram_write_data_A(system_ram0_write_data_A),
        .system_ram_write_enable_control_A(system_ram0_write_enable_control_A),

        //Slave 4(system_ram0_B)
        .system_ram_read_enable_B(system_ram0_read_enable_B),
        .system_ram_addr_B(system_ram0_addr_B),
        .system_ram_result_B(system_ram0_result_B)
    );

    //Slave 0 (boot_rom)
    rom1P #(
        .FILE_PATH("/workspaces/nano-rv32i/software/boot_rom.hex"),
        .SIZE(2304)
    ) boot_rom(
        .clk(sys_clk), .read_enable(boot_rom_read_enable),
        .address(boot_rom_addr), .result(boot_rom_result)
    );

    //Slave 1 (payload_rom)
    rom1P #(
        .FILE_PATH("/workspaces/nano-rv32i/software/payload_rom.hex"),
        .SIZE(2304)
    ) payload_rom(
        .clk(sys_clk), .read_enable(payload_rom_read_enable),
        .address(payload_rom_addr), .result(payload_rom_result)
    );

    //Slave 2 (mmio_controller)
    mmio mmio_controller(
        .clk(sys_clk), .read_enable(mmio_controller_read_enable),
        .address(mmio_controller_addr), .result(mmio_controller_result),
        .write_enable(mmio_controller_write_enable),
        .write_data(mmio_controller_write_data),
        .led_strip6(led_strip6)
    );

    //Slave 3/4 (system_ram0)
    ram2P system_ram0(
        .clk(sys_clk),

        //Slave3 (system_ram0_A)
        .read_enable_A(system_ram0_read_enable_A),
        .address0_A(system_ram0_addr_A), .result_A(system_ram0_result_A),
        .write_enable_A(system_ram0_write_enable_A),
        .write_enable_control_A(system_ram0_write_enable_control_A),
        .write_data_A(system_ram0_write_data_A),

        //Slave4 (system_ram0_B)
        .read_enable_B(system_ram0_read_enable_B),
        .address1_B(system_ram0_addr_B), .result_B(system_ram0_result_B)
    );
endmodule
