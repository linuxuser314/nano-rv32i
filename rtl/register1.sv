//Need to add a register...
`default_nettype none

module register1(input  logic data,
                  input  logic       clk, reset,
                  output logic result);
    always_ff @(posedge clk, posedge reset) begin
        if(reset) result <= 1'b0;
        else result <= data;
    end
endmodule
