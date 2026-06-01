`default_nettype none

module datapath(input logic clk, reset);
    logic RF_write_enable, ALU_src;
    logic[31:0] instruction, result_mux_out, RF_rd1, RF_rd2, decoded_immediate, ALU_src_val;
    logic I, S, B, U, J;

    decoder(
        .RF_write_enable(RF_write_enable),
        .I(I), .S(S), .B(B), .U(U), .J(J),
        .ALU_src(ALU_src)
    );
    memory_subsystem();
    PC_subsystem();
    register_file();
    imm_dec_ext(
        .I(I), .S(S), .B(B), .U(U), .J(J),
        .instruction(instruction[31:7]),
        .out(decoded_imediate)
    );

    register_file(
        .clk(clk), .reset(reset), .write_enable(RF_write_enable),
        .a1(instruction[15:19]), .a2(instruction[20:24]), .a3(instruction[7:11]),
        .rd1(RF_rd1), .rd2(RF_rd2), .wd3(result_mux_out)
    );

    mux2(
        .in0(decoded_immediate), .in1(RF_rd1), .select(ALU_src), .result(ALU_src_val)
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
