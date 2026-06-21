import random

# Expose module name to the master controller
MODULE_NAME = "shifter"

def calculate_expected(data_in, shamt, is_right_shift, is_arithmetic_shift):
    """Mathematically models the barrel shifter."""
    if not is_right_shift:
        # Left Shift 
        # (Logical and Arithmetic Left Shifts are mathematically identical; both zero-fill the LSB)
        # Our generator randomizes is_arithmetic_shift during left shifts to ensure the RTL 
        # handles this equivalence properly.
        return (data_in << shamt) & 0xFFFFFFFF
    else:
        if is_arithmetic_shift:
            # Arithmetic Right Shift (SRA) - Sign Extension
            if data_in & 0x80000000:  # If negative
                signed_data = data_in - 0x100000000
                return (signed_data >> shamt) & 0xFFFFFFFF
            else:
                return (data_in >> shamt) & 0xFFFFFFFF
        else:
            # Logical Right Shift (SRL) - Zero Extension
            return (data_in >> shamt) & 0xFFFFFFFF

def generate_vectors(num_iterations):
    """Generates the stimulus and expected results, mixing edge cases and random data."""
    vectors = []
    
    edge_cases_data = [
        0x00000000, 0xFFFFFFFF, # All 0s, All 1s (-1)
        0x7FFFFFFF, 0x80000000, # Max Pos, Max Neg (Crucial for arithmetic shift testing)
        0xAAAAAAAA, 0x55555555, # Alternating
        0x80000001, 0x00000001  # Ends set
    ]
    
    edge_cases_shamt = [0, 1, 15, 16, 31] # Boundaries and midpoints

    for _ in range(num_iterations):
        # 40% chance of Edge Case, 60% chance of Random Vector
        if random.random() < 0.4:
            data_in = random.choice(edge_cases_data)
            shamt = random.choice(edge_cases_shamt)
        else:
            data_in = random.getrandbits(32)
            shamt = random.getrandbits(5)

        is_right_shift = random.choice([0, 1])
        is_arithmetic_shift = random.choice([0, 1])

        expected_result = calculate_expected(data_in, shamt, is_right_shift, is_arithmetic_shift)
        
        # Packing map:
        # data_in[70:39] | shamt[38:34] | is_right_shift[33] | is_arithmetic_shift[32] | expected_result[31:0]
        # Total bits = 32 + 5 + 1 + 1 + 32 = 71 bits
        vector_int = (data_in << 39) | (shamt << 34) | (is_right_shift << 33) | (is_arithmetic_shift << 32) | expected_result
        
        # 71 bits fits into 18 hex characters
        vectors.append(f"{vector_int:018x}")
        
    return vectors

def get_testbench_code(num_iterations, tv_file):
    """Returns the dynamically generated SV testbench string."""
    return f"""`default_nettype none
`timescale 1ns/1ps

module {MODULE_NAME}_tb;

    // --- Inputs ---
    logic [31:0] data_in;
    logic [4:0] shamt;
    logic is_right_shift, is_arithmetic_shift;

    // --- Outputs ---
    logic [31:0] result;

    // --- Verification Variables ---
    logic [31:0] expected_result;
    
    // 71 bits wide vector
    logic [70:0] test_vectors [0:{num_iterations - 1}];
    int error_count;
    int i;

    // Instantiate the Unit Under Test (UUT)
    // NOTE: Master Controller uses -y and -Y flags, so dependencies like 'reverse32.sv' 
    // are automatically discovered and compiled by Icarus Verilog.
    {MODULE_NAME} uut (
        .data_in(data_in), 
        .shamt(shamt), 
        .is_right_shift(is_right_shift), 
        .is_arithmetic_shift(is_arithmetic_shift),
        .result(result)
    );

    initial begin
        $readmemh("{tv_file}", test_vectors);
        error_count = 0;

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            data_in = test_vectors[i][70:39];
            shamt = test_vectors[i][38:34];
            is_right_shift = test_vectors[i][33];
            is_arithmetic_shift = test_vectors[i][32];
            
            expected_result = test_vectors[i][31:0];

            #10; // Logic propagation

            if (result !== expected_result) begin
                // MIXED OUTPUT: Hex for data, Dec for shift amount, Bin for flags
                $display("ERROR [Vector %0d] - data_in:%08x shamt:%0d right:%b arith:%b", 
                         i, data_in, shamt, is_right_shift, is_arithmetic_shift);
                $display("ERROR        -> RESULT EXPECTED: %08x | GOT: %08x", expected_result, result);
                
                error_count++;
            end
        end

        $display("Verification Complete. Total Errors: %0d / %0d\\n", error_count, {num_iterations});
        $finish;
    end
endmodule
"""