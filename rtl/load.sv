//This module shifts and extends a memory word for lw, lh, lb, lhu, lbu commands in RISC-V.
//Estimated LUT usage: 70 (2 for shift calculations + 64 for shifter + 4 for fill_bit calculation)
//Estimated propogation delay: 5-LUTs (3 for fill_bit calculation and 2 for shifting).
`default_nettype none;
module load(input  logic[31:0] data,
            input  logic is_byte, is_half, is_unsigned,
            input  logic[1:0] addr_end,
            output logic[31:0] result);
    logic shift1, shift2, fill_bit;
    logic[31:0] stage;

    //This determines the shift ammount for the result from memory (which is word-aligned)
    //By looking at the last two bits of the address and whether or not it is a byte or a half-load.
    assign shift2 = (is_half & ~addr_end[1]) | (is_byte & ~addr_end[1]);
    assign shift1 = is_byte & addr_end[0];

    //This chunk of logic selects the fill bit for the shifter. It's slightly complex and should probably be refactored for readability.
    //It's pure logic-gate combinational logic but that may be obscuring the purpose.
    //It's a 9-input boolean function, which I am going to guess maps to 4 LUTs with a 3-LUT delay (conservative guess)
    //If it's unsigned, the sign bit is 0. Otherwise:
    assign fill_bit = is_unsigned ? 0 :
                      //First line pulls out the sign bit of Byte 1 if it's fetching Byte 1, second line does the same for Byte 3.
                      (data[7]  & is_byte & ~addr_end[0] & ~addr_end[1]) |
                      (data[23] & is_byte & addr_end[0] & ~addr_end[1]) |
                      //First line pulls out the sign bit of Byte 2 if it's loading the lower half or Byte 2. Second line does the same for upper half and Byte 5.
                      (data[15] & (is_half & addr_end[1] | is_byte & addr_end[1] & ~addr_end[0])) |
                      (data[31] & (is_half & addr_end[0] | is_byte & ~addr_end[0] & ~addr_end[0]));

    byte_shift_right byte_shift_right(
        .shift1(shift1), .shift2(shift2), .fill_bit(fill_bit), .data(data), .result(result)
    );


endmodule
