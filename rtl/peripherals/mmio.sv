`default_nettype none

module mmio(
        input logic clk, reset,
        output logic MMIO_FAULT,
        output logic[31:0] tohost,
        ram_bus_if.slave bus
);
    always_ff @(posedge clk) begin
        MMIO_FAULT <= 0;
        if(reset) begin
            tohost <= 0;
        end
        else if(bus.read_enable || bus.write_enable) begin
            case(bus.address)
                32'h8000_0000: begin
                    if(bus.write_enable) begin
                        tohost <= bus.write_data[31:0];
                    end
                    if(bus.read_enable) begin
                        bus.read_data <= 32'b0;
                    end
                end
                default: MMIO_FAULT <= 1;
            endcase
        end
    end
endmodule
