//This is the top SoC module.

`default_nettype none

module soc_top(
    input  logic       clk_27MHz,
    input  logic       button_1,      // Reset button (Active-High)
    input  logic       bl616_uart_rx,
    output logic       bl616_uart_tx,
    output logic [5:0] led_strip6
`ifdef VERILATOR
    , output logic [31:0] tohost
`endif
);


    //Leave them simple for now.
    logic sys_clk, sys_reset;
    assign sys_clk = clk_27MHz;
    assign sys_reset = button_1;
    logic[5:0] debug_data;
    logic MMIO_FAULT;
    logic core_FETCH_FAULT, core_DATA_FAULT;

    logic system_mode; // core execution vs. dma loading/dumping.


    ram_bus_if core_fetch_bus(); //Master 0
    ram_bus_if core_data_bus(); //Master 1
    ram_bus_if uart_dma_bus(); //Alternate Master 1
    ram_bus_if mmio_bus(); //Slave 2

    ram_bus_if system_ram0_bus_B(); // Slave 4 (DATA)


    //Master 0/1 (core_fetch, core_data)
    rv32i_core core(

        //Instruction fetching
        .fetch_bus(core_fetch_bus),
        .FETCH_FAULT(core_FETCH_FAULT),

        //Data reading/writing
        .DATA_FAULT(core_DATA_FAULT),
        .data_bus(core_data_bus),
        .debug_data(debug_data),

        .clk(sys_clk), .reset(sys_reset)
    );

    //Master-slave bus interconnect
    bus_interconnect #(
        .BOOT_ROM_SIZE(BOOT_ROM_SIZE),
        .SYSTEM_RAM0_SIZE(SYSTEM_RAM0_SIZE)
    ) master_bus(
        .clk(sys_clk), .reset(sys_reset),

        //Master 1 (core data)
        .core_data_bus(core_data_bus),
        .DATA_FAULT(core_DATA_FAULT),

        //Slave 2 (mmio_controller)
        .mmio_bus(mmio_bus),
        .MMIO_FAULT(MMIO_FAULT),

        //Slave 4 (system_ram0_B)
        .system_ram0_bus_B(system_ram0_bus_B),

        .system_mode(system_mode),
        .uart_dma_bus(uart_dma_bus)
    );
    logic fetch_fault_pre;
    always_ff @(posedge clk) begin
        if((core_fetch_bus.read_enable || core_fetch_bus.write_enable) &&
           core_fetch_bus.address >= SYSTEM_RAM_SIZE) begin
            fetch_fault_pre <= 1;
           end
           core_fetch_fault <= fetch_fault_pre;
    end

    //Slave 2 (mmio_controller)
    mmio mmio_controller(
        .clk(sys_clk),
        .reset(sys_reset),
        .bus(mmio_bus),
        .led_strip6(led_strip6),
        .debug_data(debug_data),
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
        .bus_A(core_fetch_bus),

        //Slave4 (system_ram0_B)
        .bus_B(system_ram0_bus_B)
    );
    
    uart_dma_flasher bootloader_module(
        .system_mode(system_mode),
        .uart_dma_bus(uart_dma_bus),

        .clk(sys_clk),
        .reset(sys_reset)
    );
endmodule
