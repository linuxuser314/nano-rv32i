//This module shifts, masks, and sets the write enble lines for sw/sh/sb commands.
//It uses one-hot enables for isHalf and isByte.
//It assumes that memory accesses are properly aligned. Unaligned stores are undefined behavior.

`default_nettype none

module store(input  logic[31:0] data,
             input  logic[1 :0] addr_end,
             input  logic       is_half, is_byte,
             output logic[31:0] result,
             output logic[3 :0] write_enable);

    byte_shift_left(
        .data(data), .shift1(addr_end[0]), .shift2(addr_end[1]), .fill_bit(1'b0), .result(result)
    );
endmodule
