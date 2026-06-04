`default_nettype none

/*
 * Module: reverse32
 * Description: Reverses the bit order of a 32-bit vector (bit 0 maps to bit 31, etc.).
 * * NOTE & CREDIT:
 * This standalone structural module was generated to bypass a toolchain limitation.
 * The original design intended to use the standard SystemVerilog streaming operator
 * {<<{data_in}}, which is the ideal, modern syntax for inline bit-reversal.
 * However, because the open-source Icarus Verilog (iverilog) parser lacks support
 * for streaming concatenations, this explicit generate-loop implementation was used
 * to achieve identical 0-LUT wiring results while maintaining 100% compatibility
 * with the simulation environment.
 */
module reverse32 (
    input  logic [31:0] data_in,
    output logic [31:0] data_out
);

    // The compiler unrolls this loop completely during synthesis,
    // resulting in direct wire-swapping in the FPGA fabric.
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : bit_reversal_wiring
            assign data_out[i] = data_in[31 - i];
        end
    endgenerate

endmodule