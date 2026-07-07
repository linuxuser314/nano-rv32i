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
    int boot_rom_size 4096;
    int payload_rom_size 4096;
    int system_ram0_size 4096;
    string text_hex_path;
    string data_hex_path;
    //string payload_hex_path;

    initial begin
        // 1. Check for the BOOT_ROM flag. If missing, crash safely.
        if (!$value$plusargs("BOOT_ROM=%s", text_hex_path)) begin
            $fatal(1, "ERROR: MISSING TEXT HEX PATH (+BOOT_ROM flag required)");
        end
        else begin
            $display("Loading Instructions from: %s", text_hex_path);
            $readmemh(text_hex_path, boot_rom.ram);
        end

        // 2. Check for the SYS_RAM flag. If missing, crash safely.
        if (!$value$plusargs("SYS_RAM=%s", data_hex_path)) begin
            $fatal(1, "ERROR: MISSING RAM HEX PATH (+SYS_RAM flag required)");
        end
        else begin
            $display("Loading Data from: %s", data_hex_path);
            $readmemh(data_hex_path, system_ram0.ram);
        end
        /*
        // 3. Check for the PAYLOAD_ROM flag.
        if (!$value$plusargs("PAYLOAD_ROM=%s", payload_hex_path)) begin
            $fatal(1, "ERROR: MISSING PAYLOAD HEX PATH (+PAYLOAD_ROM flag required)");
        end
        else begin
            $display("Loading Payload from: %s", payload_hex_path);
            $readmemh(payload_hex_path, payload_array);
        end
        */
    end

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
    bus_interconnect #(
        .boot_rom_size(boot_rom_size),
        .payload_rom_size(payload_rom_size),
        .system_ram0_size(system_ram0_size)
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
        //.FILE_PATH(text_hex_path),
        .SIZE(boot_rom_size)
    ) boot_rom(
        .clk(sys_clk),
        .bus(boot_rom_bus)
    );

    //Slave 1 (payload_rom)
    ram_single_port #(
        //.FILE_PATH(payload_hex_path),
        .SIZE(payload_rom_size)
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
        .SIZE(system_ram0_size)//,
       // .FILE_PATH(data_hex_path)
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
