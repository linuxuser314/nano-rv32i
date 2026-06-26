//This module shifts and extends a memory word for lw, lh, lb, lhu, lbu commands in RISC-V.
//I had to do some workarounds to prevent pesky iverilog errors
`default_nettype none
module load(input  logic[31:0] data,
            input  logic is_byte, is_half, is_unsigned,
            input  logic[1:0] addr_end,
            output logic[31:0] result);
    logic shift1, shift2, fill_bit;
    logic[31:0] stage;
    logic[15:0] selected_half, top_half, bottom_half;
    logic[7:0] selected_byte, byte_31to24, byte_23to16, byte_15to8, byte_7to0;
    logic addr0, addr1, top_bit_of_byte, top_bit_of_half;

    assign addr0 = addr_end[0];
    assign addr1 = addr_end[1];
    assign byte_31to24 = data[31:24];
    assign byte_23to16 = data[23:16];
    assign byte_15to8 = data[15:8];
    assign byte_7to0 = data[7:0];

    assign top_half = data[31:16];
    assign bottom_half = data[15:0];


    always_comb begin
        case(addr_end)
            3: selected_byte = byte_31to24;
            2: selected_byte = byte_23to16;
            1: selected_byte = byte_15to8;
            0: selected_byte = byte_7to0;
            default: selected_byte = 8'b0;
        endcase
        selected_half = addr1 ? top_half : bottom_half;
    end

    assign top_bit_of_byte = selected_byte[7];
    assign top_bit_of_half = selected_half[15];

    always_comb begin
        if(is_byte) begin
            result = {{24{is_unsigned ? 1'b0 : top_bit_of_byte}}, selected_byte};
        end else if(is_half) begin
            result = {{16{is_unsigned ? 1'b0 : top_bit_of_half}}, selected_half};
        end else begin
            result = data;
        end
    end

endmodule
