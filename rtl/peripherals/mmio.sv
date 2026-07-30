`default_nettype none

module mmio(
        input logic clk, reset,
        input logic[5:0] debug_data,
        output logic MMIO_FAULT,
        output logic[5:0] led_strip6,
        `ifdef VERILATOR
            output logic[31:0] tohost,
        `endif
        ram_bus_if.slave bus
);
    logic[31:0] counter;
    always_ff @(posedge clk) begin
        MMIO_FAULT <= 0;
        if(reset) begin
            `ifdef VERILATOR
                tohost <= '0;
            `endif
            led_strip6 <= '0;
        end
        else if(bus.read_enable || bus.write_enable) begin
            
            case(bus.address)
            `ifdef VERILATOR
                    32'h8000_0000: begin
                        if(bus.write_enable) begin
                            tohost <= bus.write_data[31:0];
                        end
                        if(bus.read_enable) begin
                            bus.read_data <= 32'b0;
                        end
                    end
                `endif
                32'h8000_0004: begin
                    if(bus.write_enable) begin
                        led_strip6 <= bus.write_data[5:0];
                    end
                    if(bus.read_enable) begin
                        bus.read_data <= '0;
                    end
                end
                default: MMIO_FAULT <= 1;
            endcase
        end
        //Dummy test to make sure bitstream is getting to its destination.
        //led_strip6[0] is nearest to the S1, while led_strip6 is nearest to the LVDS connector.
        //counter <= counter + 1;
        //led_strip6 <= ~counter[27:22];

        //led_strip6 <= debug_data;
    end
endmodule
