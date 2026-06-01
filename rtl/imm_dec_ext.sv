//This module decodes immediates from RISC-V instructions. It assumes a one-hot encoding for I, S, B, U, and J lines.

`default_nettype none
module imm_dec_ext(
    input logic I, S, B, U, J,
    input logic [31:7] instruction,
    output logic [31:0] out);
    always_comb begin
        //Will probably need to change how this works because iverilog is mad at me
        //constant selects in always_* processes are not currently supported (all bits will be included).
        unique case(1'b1)
            //I & S-type: 12-bit signed immediate.
            I: out = {{20{instruction[31]}}, instruction[31:20]};
            S: out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            //B-type: 13-bit signed offset. imm[0] is always implicit 0.
            B: out = {{20{instruction[31]}}, instruction[7], instruction[30:25],
                      instruction[11:8], 1'b0};
            //U-type: 20-bit unsigned immediate. imm[11:0] = 0.
            U: out = {instruction[31:12], 12'b0};
            //J-type: Signed 20-bit immediate, imm[0] = 0.
            J: out = {{12{instruction[31]}}, instruction[19:12], instruction[20],
                      instruction[30:21], 1'b0};
            default: out = 32'b0;
        endcase
    end
endmodule
