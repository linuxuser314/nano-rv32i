//This is the top SoC module.

//Temporary UART test top module
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

    // 1. System Reset
    logic reset;
    assign reset = button_1;

    // 2. RX Pin Synchronizer
    logic rx_sync_0, rx_sync;
    always_ff @(posedge clk_27MHz) begin
        if (reset) begin
            rx_sync_0 <= 1'b1; // UART idles HIGH
            rx_sync   <= 1'b1;
        end else begin
            rx_sync_0 <= bl616_uart_rx;
            rx_sync   <= rx_sync_0;
        end
    end

    // 3. UART RX Instantiation
    logic [7:0] rx_data;
    logic       rx_busy;
    logic       rx_error;

    uart_rx rx_inst (
        .clk(clk_27MHz),
        .reset(reset),
        .rx_pin(rx_sync),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_error(rx_error)
    );

    // 4. ASCII Case Inverter (Combinational)
    logic [7:0] tx_data;
    always_comb begin
        if ((rx_data >= 8'h41 && rx_data <= 8'h5A) || // Uppercase A-Z
            (rx_data >= 8'h61 && rx_data <= 8'h7A))   // Lowercase a-z
        begin
            tx_data = rx_data ^ 8'h20; // Toggle bit 5 to invert case
        end else begin
            tx_data = rx_data;         // Pass all other characters unmodified
        end
    end

    // 5. RX to TX Handshake Logic
    logic tx_start;
    logic tx_busy;
    logic rx_busy_prev;

    always_ff @(posedge clk_27MHz) begin
        if (reset) begin
            rx_busy_prev <= 1'b0;
            tx_start     <= 1'b0;
        end else begin
            rx_busy_prev <= rx_busy;
            tx_start     <= 1'b0; // Default to single-cycle pulse
            
            // Trigger TX on the falling edge of rx_busy, provided there was no framing error
            if (rx_busy_prev && !rx_busy && !rx_error && !tx_busy) begin
                tx_start <= 1'b1;
            end
        end
    end

    // 6. UART TX Instantiation
    uart_tx tx_inst (
        .clk(clk_27MHz),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_out(bl616_uart_tx),
        .tx_busy(tx_busy)
    );

    // 7. Debug LEDs (Active-Low)
    // Map: [Reset, RX Error, RX Busy, TX Busy, RX Line, TX Line]
    assign led_strip6 = ~{reset, rx_error, rx_busy, tx_busy, rx_sync, bl616_uart_tx};

endmodule


/*
0x0000_0000 to 0x0000_07FF: ROM (x)
0x8000_0000 to 0x8000_07FF: MMIO (rw, volatile tag in C/C++ mandatory)
0xC000_0000 to 0xC000_07FF: RAM (rwx)
Memory regions expanded to 16KB, did not update map yet!
*/
/*
`default_nettype none

module soc_top (
    input  logic       clk_27MHz,
    input  logic       button_1,      // Reset button
    input  logic       button_2,      // User button
    input  logic       bl616_uart_rx,
    output logic       bl616_uart_tx,
    output logic [5:0] led_strip6
`ifdef VERILATOR
    , output logic [31:0] tohost
`endif
);

    // 1. System Reset
    // Assuming Sipeed board standard: Buttons are pulled HIGH, go LOW when pressed.
    // Invert them internally so active = 1.
    logic reset;
    assign reset = button_1;

    // 2. Button 2 Synchronizer & Debouncer (~39ms at 27MHz)
    logic        btn2_sync_0, btn2_sync_1;
    logic        btn2_state;
    logic [19:0] debounce_cnt;
    logic        btn2_pulse;

    always_ff @(posedge clk_27MHz) begin
        if (reset) begin
            btn2_sync_0  <= 1'b0;
            btn2_sync_1  <= 1'b0;
            btn2_state   <= 1'b0;
            debounce_cnt <= '0;
            btn2_pulse   <= 1'b0;
        end else begin
            // Double-flop synchronizer to prevent metastability
            btn2_sync_0 <= ~button_2;
            btn2_sync_1 <= btn2_sync_0;
            
            // Default: no pulse
            btn2_pulse <= 1'b0; 
            
            // If the incoming signal matches our registered state, keep counter cleared
            if (btn2_sync_1 == btn2_state) begin
                debounce_cnt <= '0;
            end else begin
                debounce_cnt <= debounce_cnt + 1;
                
                // When counter hits ~1 million (39ms at 27MHz), the line is stable
                if (debounce_cnt == 20'hFFFFF) begin
                    btn2_state   <= btn2_sync_1;
                    debounce_cnt <= '0;
                    
                    // Generate a 1-cycle pulse only on the PRESS (rising edge)
                    if (btn2_sync_1 == 1'b1) begin
                        btn2_pulse <= 1'b1;
                    end
                end
            end
        end
    end

    // 3. Payload Generation (ASCII A-Z)
    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;

    always_ff @(posedge clk_27MHz) begin
        if (reset) begin
            tx_data  <= 8'h41; // ASCII 'A'
            tx_start <= 1'b0;
        end else begin
            tx_start <= 1'b0; // Single-cycle strobe default
            
            // Trigger transmission if button pulsed and UART is idle
            if (btn2_pulse && !tx_busy) begin
                tx_start <= 1'b1;
                
                // Wrap 'Z' (0x5A) back to 'A' (0x41)
                if (tx_data == 8'h5A) begin
                    tx_data <= 8'h41;
                end else begin
                    tx_data <= tx_data + 1;
                end
            end
        end
    end

    // 4. UART TX Instantiation
    uart_tx tx_inst (
        .clk(clk_27MHz),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_out(bl616_uart_tx),
        .tx_busy(tx_busy)
    );

    // 5. LED Debugging Output
    // Maps status flags to LEDs so you can verify logic before minicom output
    // LEDs are active-low. Order: [Reset, Btn2_State, TX_Busy, RX_Line...]
    assign led_strip6 = ~{reset, btn2_state, tx_busy, {3{bl616_uart_rx}}};

endmodule

/*
`default_nettype none

module soc_top(input  logic       clk_27MHz,
               input  logic       button_1, // reset button
               input  logic       button_2,  // user button
               input  logic       bl616_uart_rx,
               output logic       bl616_uart_tx,
               output logic[5:0] led_strip6,
`ifdef VERILATOR
               output logic[31:0] tohost
`endif
               );

    assign led_strip6 = ~{button_1, button_2, clk_27MHz, {3{bl616_uart_rx}}};
    assign bl616_uart_tx = bl616_uart_rx;

endmodule
/*
module soc_top(input  logic      clk_27MHz, reset_button,
               `ifdef VERILATOR
                   output logic[31:0] tohost,
                `endif
               output logic[5:0] led_strip6

               );
    localparam int BOOT_ROM_SIZE = 16;
    localparam int SYSTEM_RAM0_SIZE = 1024;
    localparam string bootloader_hex_path = "/workspaces/nano-rv32i/build/target/bootloader.hex";
    localparam string sim_payload_hex_path = "/workspaces/nano-rv32i/build/target/sim_payload.hex";


    //Leave them simple for now.
    logic sys_clk, sys_reset;
    assign sys_clk = clk_27MHz;
    assign sys_reset = reset_button;
    logic[5:0] debug_data;
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
        .debug_data(debug_data),

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
        .bus_A(system_ram0_bus_A),

        //Slave4 (system_ram0_B)
        .bus_B(system_ram0_bus_B)
    );
    
endmodule
/**/
