`default_nettype none

module uart_rx(
    input  logic       clk,
    input  logic       reset,
    input  logic       rx_pin,
    output logic [7:0] rx_data,
    output logic       rx_busy,
    output logic       rx_error
);
    typedef enum logic[1:0] {IDLE, START, DATA, STOP} uart_state;


    uart_state uart_fsm_state;
    logic [2:0] bit_counter;

    logic       half_tick;
    logic counter_reset;
    logic shift_enable;
    logic [7:0] shift_register_out;

    logic       unused_dout;
    logic [7:0] unused_byte_out;

    logic       unused_baud_tick;
    baud_generator tx_baud(
        .clk(clk),
        .reset(reset),
        .counter_reset(counter_reset),
        .baud_divider(16'd234),
        .baud_tick(unused_baud_tick),
        .half_tick(half_tick)

        
    );
    uart_shift_register tx_shift_register(
        .clk(clk),
        .reset(reset),
        .shift_enable(shift_enable),
        .din(rx_pin),
        .byte_out(shift_register_out),

        //Unused for rx
        .input_enable('0),
        .byte_in('0),
        .dout(unused_dout)
    );
    always_ff @(posedge clk) begin
        
        if(reset) begin
            uart_fsm_state <= IDLE;
            counter_reset <= 1'b1;
            bit_counter <= '0;
        end else begin
            rx_busy <= 1'b1;
            shift_enable <= '0;
            counter_reset <= '0;

            case(uart_fsm_state)
                IDLE: begin
                    rx_busy <= '0;
                    if(!rx_pin) begin
                        uart_fsm_state <= START;
                        counter_reset <= 1'b1;
                    end
                end
                START:  begin
                    if(half_tick) begin
                        if(!rx_pin) begin
                            uart_fsm_state <= DATA;
                            rx_error <= '0;
                        end else begin
                            uart_fsm_state <= IDLE;
                        end
                    end
                end
                DATA: begin
                    if(half_tick) begin
                        shift_enable <= 1'b1;
                        if(bit_counter == 3'b111) begin
                            bit_counter <= '0;
                            uart_fsm_state <= STOP;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                STOP: begin
                    if(half_tick) begin
                        if(rx_pin) begin
                            uart_fsm_state <= IDLE;
                            rx_data <= shift_register_out;
                        end else begin
                            rx_error <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end
endmodule
