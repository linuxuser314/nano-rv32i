//This is the top SoC module.


/*
0x0000_0000 to 0x0000_07FF: ROM (x)
0x4000_0000 to 0x4000_07FF: Payload (r)
0x8000_0000 to 0x8000_07FF: MMIO (rw, volatile tag in C/C++ mandatory)
0xC000_0000 to 0xC000_07FF: RAM (rwx)
*/

`default_nettype none

module soc_top(input  logic      clk_27MHz, reset_button,
               output logic[31:0] led_strip6
               );

    //Leave them simple for now.
    logic sys_clk, sys_reset;
    assign sys_clk = clk_27MHz;
    assign sys_reset = reset_button;

    logic MMIO_FAULT;
    logic core0_FETCH_FAULT, core0_DATA_FAULT;

    ram_bus_if core0_fetch_bus(); //Master 0
    ram_bus_if core0_data_bus(); //Master 1

    ram_bus_if boot_rom_bus(); //Slave 0
    ram_bus_if payload_rom_bus(); // Slave 1
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
    bus_interconnect master_bus(
        .clk(sys_clk), .reset(sys_reset),
        //Master 0 (core0 fetch)
        .core0_fetch_bus(core0_fetch_bus),
        .FETCH_FAULT(core0_FETCH_FAULT),

        //Master 1 (core0 data)
        .core0_data_bus(core0_data_bus),
        .DATA_FAULT(core0_DATA_FAULT),

        //Slave 0 (boot_rom)
        .boot_rom_bus(boot_rom_bus),

        //Slave 1 (payload_rom)
        .payload_rom_bus(payload_rom_bus),

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
        .FILE_PATH("/workspaces/nano-rv32i/software/boot_rom.hex"),
        .SIZE(512)
    ) boot_rom(
        .clk(sys_clk),
        .bus(boot_rom_bus)
    );

    //Slave 1 (payload_rom)
    ram_single_port #(
        .FILE_PATH("/workspaces/nano-rv32i/software/payload_rom.hex"),
        .SIZE(512)
    ) payload_rom(
        .clk(sys_clk),
        .bus(payload_rom_bus)
    );

    //Slave 2 (mmio_controller)
    mmio mmio_controller(
        .clk(sys_clk),
        .reset(sys_reset),
        .bus(mmio_bus),
        .led_strip6(led_strip6),
        .MMIO_FAULT(MMIO_FAULT)
    );

    //Slave 3/4 (system_ram0)
    ram_dual_port #(
        .SIZE(512)
    ) system_ram0(
        .clk(sys_clk),

        //Slave3 (system_ram0_A)
        .bus_A(system_ram0_bus_A),

        //Slave4 (system_ram0_B)
        .bus_B(system_ram0_bus_B)
    );
    `ifdef VERILATOR
        logic[31:0] last_test_output;
        always_ff @(posedge sys_clk) begin
            // Only print and update if the new data is different from the old data
            if (led_strip6 != last_test_output) begin
                // If it writes 1, it passed!
                if (led_strip6 == 32'd1) begin
                    $display("RISC-V TEST PASSED! (Code: %0d)", led_strip6);
                end else begin
                    // If it writes anything else, it failed
                    $display("RISC-V TEST FAILED! (Code: %0d)", led_strip6);
                end

                // Update our tracker so we don't print this exact number again
                last_test_output <= led_strip6;
            end
        end
    `endif
endmodule
