`default_nettype none

module datapath(input logic clk, reset);
    logic RF_write_enable, ALU_src, is_right_shift, is_arithmetic_shift,
          eq, lt, ltu, sub, negate, PC_increment, comparison_flag, is_half, is_byte, is_unsigned, is_store;
    logic[1 :0] PC_select, mask_ctrl;
    logic[31:0] instruction, result_mux_out, RF_rd1, RF_rd2, decoded_immediate, ALU_src_val,
    shift_result, mask_result, ALU_result, load_result, PC_result, prevPC, PC_plus_4, PC_plus_imm,
    new_PC, prev_PC;
    logic I, S, B, U, J;
    logic MEMORY_MISALIGNED_ERROR, INSTRUCTION_MISALIGNED_ERROR, MEMORY_OUT_OF_BOUNDS_ERROR;
    logic[2:0] result_select;
    decoder main_decoder(
        .RF_write_enable(RF_write_enable),
        .I(I), .S(S), .B(B), .U(U), .J(J),
        .ALU_src(ALU_src),
        .is_right_shift(is_right_shift), .is_arithmetic_shift(is_arithmetic_shift),
        .mask_ctrl(mask_ctrl),
        .eq(eq), .lt(lt), .ltu(ltu), .sub(sub), .negate(negate),
        .PC_select(PC_select),
        .PC_increment(PC_increment),
        .result_select(result_select),
        .MEMORY_MISALIGNED_ERROR(1'b0),
        .INSTRUCTION_MISALIGNED_ERROR(1'b0),
        .MEMORY_OUT_OF_BOUNDS_ERROR(1'b0),
        .instruction(instruction)
    );

    memory_subsystem main_memory_system(
        .load_result(load_result), //.instruction(instruction),
        .is_half(is_half), .is_byte(is_byte), .is_unsigned(is_unsigned), .is_store(is_store),
        .PC(prev_PC), .addr(ALU_result), .store_data(RF_rd2),
        .MEMORY_MISALIGNED_ERROR(MEMORY_MISALIGNED_ERROR),
        .INSTRUCTION_MISALIGNED_ERROR(INSTRUCTION_MISALIGNED_ERROR),
        .MEMORY_OUT_OF_BOUNDS_ERROR(MEMORY_OUT_OF_BOUNDS_ERROR)
    );
    //TEMPORARY: A harvard-style ROM for instructions
    instruction_rom main_instruction_memory(
        .PC(prev_PC), .instruction(instruction)
    );
    PC_subsystem PC_calculation_subsystem(
        .new_PC(PC_result), .prev_PC(prev_PC), .PC_plus_4(PC_plus_4), .PC_plus_imm(PC_plus_imm),
        .imm(decoded_immediate), .ALU_result(ALU_result),
        .PC_increment(PC_increment), .PC_select(PC_select), .branch_flag(comparison_flag)
    );
    register32 PC_tracking_register(
        .clk(clk), .reset(reset),
        .result(prev_PC), .data(PC_result)
    );
    imm_dec_ext instruction_immediate_calculator(
        .I(I), .S(S), .B(B), .U(U), .J(J),
        .instruction(instruction[31:7]),
        .out(decoded_immediate)
    );

    register_file system_register_file(
        .clk(clk), .reset(reset), .write_enable(RF_write_enable),
        .a1(instruction[19:15]), .a2(instruction[24:20]), .a3(instruction[11:7]),
        .rd1(RF_rd1), .rd2(RF_rd2), .wd3(result_mux_out)
    );

    mux2 ALU_inputb_selector(
        .in0(decoded_immediate), .in1(RF_rd2), .select(ALU_src), .result(ALU_src_val)
    );
    ALU_comparator ALU_comparison_engine(
        .a(RF_rd1), .b(ALU_src_val),
        .eq(eq), .lt(lt), .ltu(ltu), .negate(negate), .sub(sub),
        .ALU_result(ALU_result), .comparison_flag(comparison_flag)
    );
    shifter shifting_unit(
        .result(shift_result), .data_in(RF_rd1), .shamt(ALU_src_val[4:0]),
        .is_right_shift(is_right_shift), .is_arithmetic_shift(is_arithmetic_shift)
    );
    mask masking_unit(
        .a(RF_rd1), .b(ALU_src_val), .ctrl(mask_ctrl), .result(mask_result)
    );
    mux8 result_selector_mux(
        .in0(shift_result), //sll, srl, sra, slli, srli, srai
        .in1(mask_result), //and, or, xor, andi, ori, xori
        .in2({31'b0, comparison_flag}), //slt, sltu, slti, sltui
        .in3(ALU_result), //All R and I-type arithmetic instructions (except slt, sltu, slti, sltui)
        .in4(decoded_immediate), //lui
        .in5(load_result), //lw, lh, lb, lhu, lbu
        .in6(PC_plus_4), //jal, jalr
        .in7(PC_plus_imm), //auipc
        .out(result_mux_out),
        .select(result_select)
    );
endmodule
