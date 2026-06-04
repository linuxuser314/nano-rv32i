//This module decodes immediates from RISC-V instructions. It assumes a one-hot encoding for I, S, B, U, and J lines.

`default_nettype none
module imm_dec_ext(
    input logic I, S, B, U, J,
    input logic [31:7] instruction,
    output logic [31:0] out);
    // Using continuous assignments bypasses the iverilog case-statement bug completely!
    assign out = I ? {{20{instruction[31]}}, instruction[31:20]} :
                 S ? {{20{instruction[31]}}, instruction[31:25], instruction[11:7]} :
                 // Fixed the B-type sign-extension bit-count bug here too!
                 B ? {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0} :
                 U ? {instruction[31:12], 12'b0} :
                 J ? {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0} :
                 32'b0; // Default case if none match
endmodule
