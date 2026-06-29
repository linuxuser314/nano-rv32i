//This is a structural module that initiates the main memory module, handles loads/stores, and handles memory alignment errors.
`default_nettype none

module memory_subsystem(input  logic[31:0] PC, addr, store_data,
                        input  logic       is_half, is_byte, is_unsigned, is_store, is_load,
                        input  logic       clk,
                        output logic[31:0] load_result, instruction, tohost_wire,
                        output logic       MEMORY_MISALIGNED_ERROR, INSTRUCTION_MISALIGNED_ERROR,
                                           MEMORY_OUT_OF_BOUNDS_ERROR,
                        ram_bus_if.master data_bus,
                        ram_bus_if.master fetch_bus
);
    logic memory_address_misalignment, memory_address_out_of_bounds;
    //Check PC and load/store address for alignment. PC is checked with is_byte and is_half false.
    address_check address_error_checker(
        .addr_end(addr[1:0]), .is_byte(is_byte), .is_half(is_half),
        .ADDRESS_MISALIGNED_ERROR(memory_address_misalignment)
    );
    address_check instruction_error_checker(
        .addr_end(PC[1:0]), .is_byte(1'b0), .is_half(1'b0),
        .ADDRESS_MISALIGNED_ERROR(INSTRUCTION_MISALIGNED_ERROR)
    );

    assign MEMORY_MISALIGNED_ERROR = (is_store | is_load) & memory_address_misalignment;

    //Wire up the memory unit!
    logic[31:0] RD2, WD2;
    logic[3:0] write_enable, write_enable_output;


    //Connect load-store units to memory_subsystem inputs and outputs and to main memory module.
    store store_calculation_unit(
        .data(store_data), .result(WD2),
        .addr_end(addr[1:0]), .is_half(is_half), .is_byte(is_byte),
        .write_enable(write_enable_output)
    );
    assign write_enable = write_enable_output & {4{is_store}};
    load load_mask_shift_and_extend(
        .data(RD2), .result(load_result), .addr_end(addr[1:0]),
        .is_byte(is_byte), .is_half(is_half), .is_unsigned(is_unsigned)
    );

endmodule
