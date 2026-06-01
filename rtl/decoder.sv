//Decoder dummy module
`default_nettype none

module decoder(input  logic[31:0] instruction,
               input  logic        clk, reset,
                                   MEMORY_MISALIGNED_ERROR,
                                   INSTRUCTION_MISALIGNED_ERROR,
                                   MEMORY_OUT_OF_BOUNDS_ERROR,
                output logic I, S, B, U, J, is_byte, is_half, is_unsigned, is_store,
                             eq, lt, ltu, negate, sub, PC_increment,
                             is_right_shift, is_arithmetic_shift,
                output logic[1:0] mask_ctrl, PC_select
                );

endmodule
