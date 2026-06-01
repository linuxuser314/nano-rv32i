`default_nettype none

module datapath(input logic clk, reset);
    logic RF_write_enable, ALU_src, is_right_shift, is_arithmetic_shift,
          eq, lt, ltu, sub, negate;
    logic[31:0] instruction, result_mux_out, RF_rd1, RF_rd2, decoded_immediate, ALU_src_val,
    shift_result, mask_result, ALU_result, load_result;
    logic I, S, B, U, J;
    logic MEMORY_MISALIGNED_ERROR, INSTRUCTION_MISALIGNED_ERROR, MEMORY_OUT_OF_BOUNDS_ERROR;

    decoder(
        .RF_write_enable(RF_write_enable),
        .I(I), .S(S), .B(B), .U(U), .J(J),
        .ALU_src(ALU_src),
        .is_right_shift(is_right_shift), .is_arithmetic_shift(is_arithmetic_shift),
        .eq(eq), .lt(lt), .ltu(ltu), .sub(sub), .negate(negate),
        .ALU_result(ALU_result),
        .MEMORY_MISALIGNED_ERROR(MEMORY_MISALIGNED_ERROR),
        .INSTRUCTION_MISALIGNED_ERROR(INSTRUCTION_MISALIGNED_ERROR),
        .MEMORY_OUT_OF_BOUNDS_ERROR(MEMORY_OUT_OF_BOUNDS_ERROR)
    );

    memory_subsystem(
        .load_result(load_result), .instruction(instruction),
        .is_half(is_half), .is_byte(is_byte), .is_unsigned(is_unsigned), .is_store(is_store),
        .PC(), .addr(), .store_data(),
        .MEMORY_MISALIGNED_ERROR(MEMORY_MISALIGNED_ERROR),
        .INSTRUCTION_MISALIGNED_ERROR(INSTRUCTION_MISALIGNED_ERROR),
        .MEMORY_OUT_OF_BOUNDS_ERROR(MEMORY_OUT_OF_BOUNDS_ERROR)
    );
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
    ALU_comparator(
        .a(RF_rd1), .b(ALU_src_val),
        .eq(eq), .lt(lt), .ltu(ltu), .negate(negate), .sub(sub),
        .ALU_result(ALU_result), .comparison_flag(comparison_flag)
    );
    shifter(
        .result(shift_result), .data_in(RF_rd1), .shamt(ALU_src_val[4:0]),
        .is_right_shift(is_right_shift), .is_arithmetic_shift(is_arithmetic_shift)
    );
    mask(
        .a(RF_rd1), .b(ALU_src_val), .ctrl(mask_ctrl), .result(mask_result)
    );
    mux8(
        .in0(shift_result), //sll, srl, sra, slli, srli, srai
        .in1(mask_result), //and, or, xor, andi, ori, xori
        .in2(comparison_flag), //slt, sltu, slti, sltui
        .in3(ALU_result), //All R and I-type arithmetic instructions (except slt, sltu, slti, sltui)
        .in4(decoded_immediate), //lui
        .in5(load_result), //lw, lh, lb, lhu, lbu
        .in6(PC_plus_4), //jal, jalr
        .in7(PC_plus_immediate), //auipc
        .out(result_mux_out),
        .select(result_select)
    );
endmodule
