//This module shifts, masks, and sets the write enble lines for sw/sh/sb commands.
//It uses one-hot enables for isHalf and isByte.
//It assumes that memory accesses are properly aligned. Unaligned stores are undefined behavior.

`default_nettype none

module store(input  logic[31:0] data,
             input  logic[1 :0] addr_end,
             input  logic       is_half, is_byte,
             output logic[31:0] result,
             output logic[3 :0] write_enable);

    byte_shift_left byte_shift_left(
        .data(data), .shift1(addr_end[0]), .shift2(addr_end[1]), .fill_bit(1'b0), .result(result)
    );

    logic is_word;
    assign is_word = ~(is_half | is_byte);

    //Like in the load fill_bit calculator, this is a lot of combinational logic!
    //It is difficult to read and I should probably clean it up.
    //There is also a lot of duplicated logic and I'm not sure if Yosys will optimize it away for me or not, so I should probably optimize it at some point.
    //Basically I'm setting each WE bit if it is a word OR if it's a half that's on that byte OR it's a byte on that byte.
    assign write_enable[0] =  ~(is_half | is_byte) |
                             (is_half & ~addr_end[1]) |
                             (is_byte & ~addr_end[1] & ~addr_end[0]);
    assign write_enable[1] =  ~(is_half | is_byte) |
                             (is_half & ~addr_end[1]) |
                             (is_byte & ~addr_end[1] & addr_end[0]);
    assign write_enable[2] =  ~(is_half | is_byte)|
                             (is_half & addr_end[1]) |
                             (is_byte & addr_end[1] & ~addr_end[0]);
    assign write_enable[3] =  ~(is_half | is_byte) |
                             (is_half & addr_end[1]) |
                             (is_byte & addr_end[1] & addr_end[0]);


endmodule
