`default_nettype none

module dff_register #(
                parameter int SIZE = 1,
                parameter logic[SIZE-1:0] RESET_VALUE = '0
                ) (
                input logic[SIZE - 1:0] din,
                input  logic       clk, reset, en,
                output logic[SIZE - 1:0] dout);
    always_ff @(posedge clk) begin
        if(reset) dout <= RESET_VALUE;
        else if(en) dout <= din;
    end
endmodule
