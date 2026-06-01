//This is a structural module that initiates the main memory module, handles loads/stores, and handles memory alignment errors.
`default_nettype none

module memory_subsystem(input  logic[31:0] PC, addr, store_data,
                        input  logic       is_half, is_byte, is_unsigned, is_store,
                        output logic[31:0] load_result, instruction,
                        output logic       MEMORY_MISALIGNED_ERROR, INSTRUCTION_MISALIGNED_ERROR,
                                           MEMORY_OUT_OF_BOUNDS_ERROR
);
    //Check PC and load/store address for alignment. PC is checked with is_byte and is_half false.
    address_check(
        .addr_end(addr[1:0]), .is_byte(is_byte), .is_half(is_half),
        .ADDRESS_MISALIGNED_ERROR(MEMORY_MISALIGNED_ERROR)
    );
    address_check(
        .addr_end(PC[1:0]), .is_byte(1'b0), is_half(1'b0),
        .ADDRESS_MISALIGNED_ERROR(INSTRUCTION_MISALIGNED_ERROR)
    );

    //Wire up the memory unit!
    logic[31:0] RD2, WD2;
    logic[3:0] write_enable;
    memory(
        .A1(PC), .A2(addr), .RD1(instruction), .RD2(RD2), .WD2(WD2), .write_enable(write_enable),
        .MEMORY_OUT_OF_BOUNDS_ERROR(MEMORY_OUT_OF_BOUNDS_ERROR)
    );

    //Connect load-store units to memory_subsystem inputs and outputs and to main memory module.
    store(
        .data(store_data), .result(WD2),
        .addr_end(addr[1:0]), .is_half(is_half), .is_byte(is_byte),
        .write_enable(write_enable & {4{is_store}})
    );
    load(
        .data(RD2), .result(load_result), .addr_end(addr[1:0]),
        .is_byte(is_byte), .is_half(is_half), .is_unsigned(is_unsigned)
    );

endmodule
