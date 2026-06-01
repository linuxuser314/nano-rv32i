//Address alignment checker module. Takes is_byte, is_half, and addr_end and may trigger MEMORY_MISALIGNED error message.

`default_nettype none

module address_check(input  logic[1:0] addr_end,
                     input  logic      is_byte, is_half,
                     output logic      MEMORY_MISALIGNED_ERROR);
    //If it's a word and it's not 4 bit aligned or it's a half and it's not 2-bit aligned, enable the error line.
    assign MEMORY_MISALIGNED_ERROR = ~(is_byte | is_half) & (addr_end[0] | addr_end[1]) |
                                      (is_half & addr_end[0]);
endmodule
