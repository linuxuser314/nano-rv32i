`default_nettype none

module rv32i_core(input logic clk, reset,
                  input logic DATA_FAULT, FETCH_FAULT,
                  output logic debug_data[5:0],
                  ram_bus_if.master fetch_bus,
                  ram_bus_if.master data_bus);

    logic RF_write_enable, ALU_src, is_right_shift, is_arithmetic_shift,
          eq, lt, ltu, sub, negate, PC_increment, comparison_flag,
          is_half, is_byte, is_unsigned, is_store, is_load;
    logic[1 :0] PC_select, mask_ctrl;
    logic[31:0] instruction, result_mux_out, RF_rd1, RF_rd2, decoded_immediate, ALU_src_val,
    shift_result, mask_result, load_result, PC_result, PC_plus_4, PC_plus_imm, prev_PC;
    logic I, S, B, U, J;
    logic STORE_FAULT, STORE_MISALIGNED, LOAD_FAULT, LOAD_MISALIGNED,
    FETCH_MISALIGNED, INVALID_INSTRUCTION;
    logic current_cycle_is_end_of_load, previous_cycle_was_start_of_load;
    logic[2:0] result_select;
    (* keep *) logic[31:0] ALU_result;

    always debug_data = PC_result[7:2];
`ifdef RISCV_FORMAL
    logic FAULT;
    assign FAULT = LOAD_FAULT || LOAD_MISALIGNED || STORE_FAULT || STORE_MISALIGNED ||
                   FETCH_FAULT || FETCH_MISALIGNED || INVALID_INSTRUCTION;
`endif
    decoder main_decoder(
        .RF_write_enable(RF_write_enable),
        .I(I), .S(S), .B(B), .U(U), .J(J),
        .ALU_src(ALU_src),
        .is_right_shift(is_right_shift), .is_arithmetic_shift(is_arithmetic_shift),
        .is_half(is_half), .is_byte(is_byte),
        .is_store(is_store), .is_load(is_load), .is_unsigned(is_unsigned),//This is what was missing
        .previous_cycle_was_start_of_load(previous_cycle_was_start_of_load),
        .current_cycle_is_end_of_load(current_cycle_is_end_of_load),
        .mask_ctrl(mask_ctrl),
        .eq(eq), .lt(lt), .ltu(ltu), .sub(sub), .negate(negate),
        .PC_select(PC_select),
        .PC_increment(PC_increment),
        .result_select(result_select),
        .opcode(instruction[6:0]),
        .funct7(instruction[31:25]),
        .funct3(instruction[14:12]),
        .INVALID_INSTRUCTION(INVALID_INSTRUCTION)
    );
    dff_register #(
        .SIZE(1)
    ) load_stall_flag_register(
        .clk(clk), .reset(reset), .en(1'b1),
        .din(previous_cycle_was_start_of_load),
        .dout(current_cycle_is_end_of_load)
    );
    fetch_unit main_fetch_unit(
        .PC(PC_result), .instruction(instruction),
        .FETCH_MISALIGNED(FETCH_MISALIGNED),
        .bus(fetch_bus)
    );
    load_store_unit main_memory_unit(
        .is_half(is_half), .is_byte(is_byte), .is_word(~(is_byte | is_half)),
        .is_unsigned(is_unsigned), .is_store(is_store), .is_load(is_load),
        .address(ALU_result), .store_data(RF_rd2), .load_result(load_result),
        .LOAD_MISALIGNED(LOAD_MISALIGNED), .STORE_MISALIGNED(STORE_MISALIGNED),
        .LOAD_FAULT(LOAD_FAULT), .STORE_FAULT(STORE_FAULT),
        .DATA_FAULT(DATA_FAULT),//This is an input signal

        .bus(data_bus)
    );
    PC_subsystem PC_calculation_subsystem(
        .new_PC(PC_result), .prev_PC(prev_PC),
        .PC_plus_4(PC_plus_4), .PC_plus_imm(PC_plus_imm),
        .imm(decoded_immediate), .jalr_addr({ALU_result[31:1], 1'b0}),
        .PC_increment(PC_increment), .PC_select(PC_select), .branch_flag(comparison_flag),
        .FAULT(LOAD_FAULT || LOAD_MISALIGNED || STORE_FAULT || STORE_MISALIGNED ||
               FETCH_FAULT || /*FETCH_MISALIGNED || Causing a combinational loop, will fix when pipelining*/ INVALID_INSTRUCTION),
        .reset(reset)
    );
    dff_register #(
        .SIZE(32),
        `ifdef VERILATOR
            .RESET_VALUE(32'hC000_0000)
        `else
            .RESET_VALUE('0)
        `endif
    ) PC_tracking_register(
        .clk(clk), .reset(reset), .en(1'b1),
        .din(PC_result), .dout(prev_PC)
    );

    imm_dec_ext instruction_immediate_calculator(
        .I(I), .S(S), .B(B), .U(U), .J(J),
        .instruction(instruction[31:7]),
        .out(decoded_immediate)
    );

    register_file system_register_file(
        .clk(clk), .write_enable(RF_write_enable),
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
    // =================================================================
    // SIMULATION ONLY: Hardware Fault Monitor
    // =================================================================
    `ifdef VERILATOR
        always_ff @(posedge clk) begin
            if (reset == 0) begin
                if (LOAD_FAULT)          $display("HARDWARE FAULT: LOAD_FAULT at PC 0x%08x", prev_PC);
                if (STORE_FAULT)         $display("HARDWARE FAULT: STORE_FAULT at PC 0x%08x", prev_PC);
                if (LOAD_MISALIGNED)     $display("HARDWARE FAULT: LOAD_MISALIGNED at PC 0x%08x", prev_PC);
                if (STORE_MISALIGNED)    $display("HARDWARE FAULT: STORE_MISALIGNED at PC 0x%08x", prev_PC);
                if (FETCH_FAULT)         $display("HARDWARE FAULT: FETCH_FAULT at PC 0x%08x", prev_PC);
                if (FETCH_MISALIGNED)    $display("HARDWARE FAULT: FETCH_MISALIGNED at PC 0x%08x", prev_PC);
                if (INVALID_INSTRUCTION) $display("HARDWARE FAULT: INVALID_INSTRUCTION (0x%08x) at PC 0x%08x", instruction, prev_PC);
            end
        end
    `endif
endmodule
