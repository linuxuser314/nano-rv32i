`default_nettype none

module load_store_unit(ram_bus_if.master bus,
                  output logic LOAD_MISALIGNED, STORE_MISALIGNED, LOAD_FAULT, STORE_FAULT,
                  input logic DATA_FAULT,
                  input logic is_word, is_half, is_byte, is_store, is_load, is_unsigned,
                  input logic[31:0] address, store_data,
                  output logic[31:0] load_result

                  );
    logic MISALIGNED;
    logic[3:0] write_enable_output;
    assign MISALIGNED = (is_word & (address[0] | address[1])) | (is_half & address[0]);
    assign bus.write_enable = is_store & ~MISALIGNED;
    assign bus.read_enable = is_load & ~MISALIGNED;
    assign bus.address = {address[31:2], 2'b00};
    store store_calculation_unit(
        .data(store_data), .result(bus.write_data),
        .addr_end(address[1:0]), .is_half(is_half), .is_byte(is_byte),
        .write_enable(write_enable_output)
    );
    assign bus.write_enable_control = write_enable_output & {4{is_store}};
    load load_mask_shift_and_extend(
        .data(bus.read_data), .result(load_result), .addr_end(address[1:0]),
        .is_byte(is_byte), .is_half(is_half), .is_unsigned(is_unsigned)
    );

    always_comb begin
        LOAD_MISALIGNED = MISALIGNED & is_load;
        STORE_MISALIGNED = MISALIGNED & is_store;
        LOAD_FAULT = DATA_FAULT & is_load;
        STORE_FAULT = DATA_FAULT & is_store;
    end

endmodule