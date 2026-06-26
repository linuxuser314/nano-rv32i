//Need to add a register...
`default_nettype none

module register32(input  logic[31:0] data,
                  input  logic       clk, reset,
                  output logic[31:0] result);
    initial result = 32'b0;
    always_ff @(posedge clk, posedge reset) begin
        if(reset) result <= 32'b0;
        else result <= data;
    end
endmodule
