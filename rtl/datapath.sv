`default_nettype none

module datapath(input logic clk, reset);
    logic RF_write_enable;
    logic[31:0] instruction, result_mux_out, RF_rd1, RF_rd2;
    decoder(
        .RF_write_enable(RF_write_enable)
    );
    memory_subsystem();
    PC_subsystem();
    register_file();
    imm_dec_ext();

    register_file(
        .clk(clk), .reset(reset), .write_enable(RF_write_enable),
        .a1(instruction[15:19]), .a2(instruction[20:24]), .a3(instruction[7:11]),
        .rd1(RF_rd1), .rd2(RF_rd2), .wd3(result_mux_out)
    );

    ALU_comparator();
    shifter();
    mask();
    mux8(
        .in0(),
        .in1(),
        .in2(),
        .in3(),
        .in4(),
        .in5(),
        .in6(),
        .in7(),
        .out(result_mux_out),
        .select(result_select)
    );
endmodule
