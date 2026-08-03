`default_nettype none

module baud_generator(
    input  logic        clk,
    input  logic        reset,
    input  logic        counter_reset,
    input  logic [15:0] baud_divider,
    output logic        baud_tick,
    output logic        half_tick
);
    logic [15:0] counter;
    always_ff @(posedge clk) begin

        baud_tick <= '0;
        half_tick <= '0;

        if(reset || counter_reset) begin
            counter <= '0;
        end else begin
            counter <= counter + 1;
            if(counter == baud_divider - 1) begin
                counter <= '0;
                baud_tick <= '1;
            end
            if(counter == (baud_divider >> 1)) begin
                half_tick <= '1;
            end
        end
    end
endmodule
