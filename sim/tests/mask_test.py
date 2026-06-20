import random

# Expose module name to the master controller
MODULE_NAME = "mask"

def calculate_expected(a, b, ctrl):
    """Mathematically models the bitwise mask result."""
    if ctrl == 0:
        return (a & b) & 0xFFFFFFFF
    elif ctrl == 1:
        return (a | b) & 0xFFFFFFFF
    elif ctrl == 2:
        return (a ^ b) & 0xFFFFFFFF
    else:
        return 0

def generate_vectors(num_iterations):
    """Generates the stimulus and expected results, mixing edge cases and random data."""
    vectors = []
    
    edge_cases = [
        0x00000000, 0xFFFFFFFF, # All 0s, All 1s
        0x7FFFFFFF, 0x80000000, # Max Pos, Max Neg
        0xAAAAAAAA, 0x55555555, # Alternating
        0xF0F0F0F0, 0x0F0F0F0F, # Nibble alternating
        0x00000001, 0xFFFFFFFE  # 1, -2
    ]

    for _ in range(num_iterations):
        # 40% chance of Edge Case, 60% chance of Random Vector
        if random.random() < 0.4:
            a = random.choice(edge_cases)
            b = random.choice(edge_cases)
        else:
            a = random.getrandbits(32)
            b = random.getrandbits(32)

        ctrl = random.randint(0, 3)

        expected_result = calculate_expected(a, b, ctrl)
        
        # Packing map: a[97:66] | b[65:34] | ctrl[33:32] | expected_result[31:0]
        # Total bits = 32 + 32 + 2 + 32 = 98 bits
        vector_int = (a << 66) | (b << 34) | (ctrl << 32) | expected_result
        
        # 98 bits fits into 25 hex characters (100 bits max)
        vectors.append(f"{vector_int:025x}")
        
    return vectors

def get_testbench_code(num_iterations, tv_file):
    """Returns the dynamically generated SV testbench string using HEX display."""
    return f"""`default_nettype none
`timescale 1ns/1ps

module {MODULE_NAME}_tb;

    // --- Inputs ---
    logic [31:0] a, b;
    logic [1:0] ctrl;

    // --- Outputs ---
    logic [31:0] result;

    // --- Verification Variables ---
    logic [31:0] expected_result;
    
    // 98 bits wide vector
    logic [97:0] test_vectors [0:{num_iterations - 1}];
    int error_count;
    int i;

    // Instantiate the Unit Under Test (UUT)
    {MODULE_NAME} uut (
        .a(a), .b(b), .ctrl(ctrl),
        .result(result)
    );

    initial begin
        $readmemh("{tv_file}", test_vectors);
        error_count = 0;

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            a = test_vectors[i][97:66];
            b = test_vectors[i][65:34];
            ctrl = test_vectors[i][33:32];
            
            expected_result = test_vectors[i][31:0];

            #10; // Logic propagation

            if (result !== expected_result) begin
                // HEX/BIN OUTPUT for easier bitwise logic debugging
                $display("ERROR [Vector %0d] - a:%08x b:%08x ctrl:%b", i, a, b, ctrl);
                $display("ERROR        -> RESULT EXPECTED: %08x | GOT: %08x", expected_result, result);
                
                error_count++;
            end
        end

        $display("Verification Complete. Total Errors: %0d / %0d\\n", error_count, {num_iterations});
        $finish;
    end
endmodule
"""