import random

# Expose module name to the master controller
MODULE_NAME = "ALU_comparator"

def calculate_expected(a, b, eq, lt, ltu, negate, sub):
    """Mathematically models the ALU result and comparison flag."""
    if sub:
        alu_res = (a - b) & 0xFFFFFFFF
    else:
        alu_res = (a + b) & 0xFFFFFFFF
        
    base_flag = 0
    if sub:
        if eq:
            base_flag = 1 if a == b else 0
        elif lt:
            signed_a = a - 0x100000000 if a & 0x80000000 else a
            signed_b = b - 0x100000000 if b & 0x80000000 else b
            base_flag = 1 if signed_a < signed_b else 0
        elif ltu:
            base_flag = 1 if a < b else 0
            
    comp_flag = (1 - base_flag) if negate else base_flag
    return alu_res, comp_flag

def generate_vectors(num_iterations):
    """Generates the stimulus and expected results, mixing edge cases and random data."""
    vectors = []
    comp_types = ['eq', 'lt', 'ltu', 'none']
    
    edge_cases = [
        0x00000000, 0xFFFFFFFF, # 0, -1
        0x7FFFFFFF, 0x80000000, # Max Pos, Max Neg
        0xAAAAAAAA, 0x55555555, # Alternating
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
            # Occasional identical variables to stress test 'eq' branch
            if random.random() > 0.8:
                b = a

        comp_selection = random.choice(comp_types)
        eq = 1 if comp_selection == 'eq' else 0
        lt = 1 if comp_selection == 'lt' else 0
        ltu = 1 if comp_selection == 'ltu' else 0
        
        # FIX: 'sub' MUST BE 1 for comparisons to function properly per updated specification.
        if comp_selection != 'none':
            sub = 1
        else:
            sub = random.choice([0, 1])
            
        negate = random.choice([0, 1])

        alu_res, comp_flag = calculate_expected(a, b, eq, lt, ltu, negate, sub)
        
        # Packing map: a[101:70] | b[69:38] | eq[37] | lt[36] | ltu[35] | negate[34] | sub[33] | alu_res[32:1] | comp_flag[0]
        vector_int = (a << 70) | (b << 38) | (eq << 37) | (lt << 36) | (ltu << 35) | \
                     (negate << 34) | (sub << 33) | (alu_res << 1) | comp_flag
        
        vectors.append(f"{vector_int:026x}")
        
    return vectors

def get_testbench_code(num_iterations, tv_file):
    """Returns the dynamically generated SV testbench string using DECIMAL display."""
    return f"""`default_nettype none
`timescale 1ns/1ps

module {MODULE_NAME}_tb;

    // --- Inputs ---
    logic [31:0] a, b;
    logic eq, lt, ltu, negate, sub;

    // --- Outputs ---
    logic [31:0] ALU_result;
    logic comparison_flag;

    // --- Verification Variables ---
    logic [31:0] expected_ALU_result;
    logic expected_comparison_flag;
    
    // 102 bits wide vector
    logic [101:0] test_vectors [0:{num_iterations - 1}];
    int error_count;
    int i;

    {MODULE_NAME} uut (
        .a(a), .b(b), .eq(eq), .lt(lt), .ltu(ltu),
        .negate(negate), .sub(sub),
        .ALU_result(ALU_result), .comparison_flag(comparison_flag)
    );

    initial begin
        $readmemh("{tv_file}", test_vectors);
        error_count = 0;

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            a = test_vectors[i][101:70];
            b = test_vectors[i][69:38];
            eq = test_vectors[i][37];
            lt = test_vectors[i][36];
            ltu = test_vectors[i][35];
            negate = test_vectors[i][34];
            sub = test_vectors[i][33];
            
            expected_ALU_result = test_vectors[i][32:1];
            expected_comparison_flag = test_vectors[i][0];

            #10; // Logic propagation

            if (ALU_result !== expected_ALU_result || comparison_flag !== expected_comparison_flag) begin
                // DECIMAL OUTPUT (%0d instead of %08x) for easier arithmetic debugging
                $display("ERROR [Vector %0d] - a:%0d b:%0d sub:%b eq:%b lt:%b ltu:%b neg:%b", 
                         i, a, b, sub, eq, lt, ltu, negate);
                         
                if (ALU_result !== expected_ALU_result) begin
                    $display("ERROR        -> ALU_RESULT EXPECTED: %0d | GOT: %0d", expected_ALU_result, ALU_result);
                end
                if (comparison_flag !== expected_comparison_flag) begin
                    $display("ERROR        -> COMP_FLAG  EXPECTED: %b | GOT: %b", expected_comparison_flag, comparison_flag);
                end
                
                error_count++;
            end
        end

        $display("Verification Complete. Total Errors: %0d / %0d\\n", error_count, {num_iterations});
        $finish;
    end
endmodule
"""