`default_nettype none

module uart_tx(
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    input  logic       tx_start,
    output logic       tx_out,
    output logic       tx_busy
);
    typedef enum logic[1:0] {IDLE, START, DATA, STOP} uart_state;


    uart_state uart_fsm_state;
    logic [2:0] bit_counter;

    logic baud_tick;
    logic counter_reset;
    logic shift_enable;
    logic input_enable;
    logic shift_register_out;


    logic       unused_half_tick;
    logic [7:0] unused_byte_out;
    baud_generator tx_baud(
        .clk(clk),
        .reset(reset),
        .counter_reset(counter_reset),
        .baud_divider(16'd234),
        .baud_tick(baud_tick),

        //Unused for tx
        .half_tick(unused_half_tick)

        
    );
    uart_shift_register tx_shift_register(
        .clk(clk),
        .reset(reset),
        .shift_enable(shift_enable),
        .input_enable(input_enable),
        .dout(shift_register_out),
        .byte_in(tx_data),

        //Unused for tx
        .din('0),
        .byte_out(unused_byte_out)
    );
    always_ff @(posedge clk) begin
        counter_reset <= '0;
        input_enable <= '0;
        shift_enable <= '0;
        tx_out <= 1'b1;
        tx_busy <= 1'b1;
        if(reset) begin
            uart_fsm_state <= IDLE;
            counter_reset <= 1'b1;
            bit_counter <= '0;
        end else begin
            case(uart_fsm_state)
                IDLE: begin
                    tx_out <= 1'b1;
                    tx_busy <= 1'b0;
                    if(tx_start) begin
                        tx_busy <= 1'b1;
                        counter_reset <= 1'b1;
                        uart_fsm_state <= START;
                        input_enable <= 1'b1;
                    end
                end
                START:  begin
                    tx_out <= 1'b0;
                    if(baud_tick) begin
                        uart_fsm_state <= DATA;
                    end
                end
                DATA: begin
                    tx_out <= shift_register_out;
                    if(baud_tick) begin
                        shift_enable <= 1'b1;
                        if(bit_counter == 3'b111) begin
                            uart_fsm_state <= STOP;
                        end
                        bit_counter <= bit_counter + 1;
                    end
                end
                STOP: begin
                    tx_out <= 1'b1;
                    if(baud_tick) begin
                        uart_fsm_state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
