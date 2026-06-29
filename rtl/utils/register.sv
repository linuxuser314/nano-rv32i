`default_nettype none

module register #(
                parameter int SIZE = 1
                ) (
                input logic[SIZE - 1:0] din,
                input  logic       clk, reset, en,
                output logic[SIZE - 1:0] dout);
    always_ff @(posedge clk) begin
        if(reset) dout <= '0;
        else if(en) dout <= din;
    end
endmodule
