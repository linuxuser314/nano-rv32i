`default_nettype none


module bus_interconnect #(
    parameter int SYSTEM_RAM0_SIZE = 4096
)(
    input  logic      clk,
    input  logic      reset,
    input  logic      system_mode,

    ram_bus_if.slave  uart_dma_bus,

    ram_bus_if.slave  core0_data_bus,
    output logic      DATA_FAULT,

    ram_bus_if.master mmio_bus,
    input  logic      MMIO_FAULT,

    ram_bus_if.master system_ram0_bus_B
);

    logic[1:0] data_select;
    logic[1:0] data_select_buffered;

    always_comb begin

        mmio_bus.address = core0_data_bus.address;
        mmio_bus.write_data = 32'b0;
        mmio_bus.write_enable = 1'b0;
        mmio_bus.write_enable_control = 4'b0;

        system_ram0_bus_B.address = core0_data_bus.address;
        system_ram0_bus_B.write_data = 32'b0;
        system_ram0_bus_B.write_enable = 1'b0;
        system_ram0_bus_B.write_enable_control = 4'b0;

        DATA_FAULT = 1'b0;
        data_select = 2'b0;

        //if MMIO
                if(core0_data_bus.address >= 32'h8000_0000 &&
                core0_data_bus.address < 32'h8000_07FF) begin
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
            //if RAM
                //0xC000_0000 to 0xC000_07FF: RAM (rwx)
                if(core0_data_bus.address >= 32'hC000_0000 &&
                core0_data_bus.address < (32'hC000_0000 + 32'(SYSTEM_RAM0_SIZE * 4))) begin
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
        if(MMIO_FAULT) begin
            DATA_FAULT = 1;
        end
    end


    dff_register #(
        .SIZE(2)
    ) data_select_buffer(
        .din(data_select),
        .dout(data_select_buffered),
        .clk(clk), .reset(reset), .en(1'b1)
    );

always_comb begin
        mmio_bus.read_enable = 1'b0;
        system_ram0_bus_B.read_enable = 1'b0;
        case(data_select)
            2'b10: begin
                mmio_bus.read_enable = 1'b1;
            end
            2'b11: begin
                system_ram0_bus_B.read_enable = 1'b1;
            end
            default: begin end//Defaults handled by default assignment above
        endcase
    end
    always_comb begin
        case(data_select_buffered)
            2'b01: begin
                core0_data_bus.read_data = 32'b0;
            end
            2'b10: begin
                core0_data_bus.read_data = mmio_bus.read_data;
            end
            2'b11: begin
                core0_data_bus.read_data = system_ram0_bus_B.read_data;
            end
            default: core0_data_bus.read_data = 32'b0;
        endcase
    end
endmodule
