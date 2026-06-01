//This module shifts, masks, and sets the write enble lines for sw/sh/sb commands.
//It uses one-hot enables for isHalf and isByte.
//It assumes that memory accesses are properly aligned. Unaligned stores are undefined behavior.

`default_nettype none

module store(input  logic[31:0] data,
             input  logic[1 :0] addr_end,
             input  logic       is_half, is_byte,
             output logic[31:0] result);
endmodule
