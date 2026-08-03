`default_nettype none

module uart_shift_register (
    input  logic       clk,
    input  logic       reset,
    input  logic       shift_enable,
    input  logic       input_enable,
    input  logic       din,
    input  logic [7:0] byte_in,
    output logic [7:0] byte_out,
    output logic       dout
);
    always_ff @(posedge clk) begin
        if(reset) begin
            byte_out <= 8'b0;
        end else if(input_enable) begin
            byte_out <= byte_in;
        end else if(shift_enable) begin
            byte_out <= {din, byte_out[7:1]};
        end
    end

    assign dout = byte_out[0];

endmodule
