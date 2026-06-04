import random

# Expose module name to the master controller
MODULE_NAME = "PC_subsystem"

def calculate_expected(prev_PC, imm, ALU_result, PC_select, branch_flag, PC_increment):
    """Mathematically models the PC subsystem's combinational routing and addition."""
    
    # Combinational adders always compute their values regardless of stalls/selections
    pc_plus_4 = (prev_PC + 4) & 0xFFFFFFFF
    pc_plus_imm = (prev_PC + imm) & 0xFFFFFFFF
    
    # Evaluate new_PC routing
    # NOTE: PC_increment == 0 acts as a STALL signal, but ONLY applies if we aren't taking a jump/branch.
    if PC_select == 1:
        # JAL
        new_PC = pc_plus_imm
    elif PC_select == 2:
        # JALR (automatically masks LSB to 0 per RISC-V spec)
        new_PC = ALU_result & 0xFFFFFFFE
    elif PC_select == 3 and branch_flag:
        # Branch taken
        new_PC = pc_plus_imm
    else:
        # Normal instruction or branch not taken.
        # PC_increment == 0 means stall (keep prev_PC). PC_increment == 1 means proceed (PC + 4).
        new_PC = pc_plus_4 if PC_increment else prev_PC

    return new_PC, pc_plus_4, pc_plus_imm

def generate_vectors(num_iterations):
    """Generates the stimulus and expected results, mixing edge cases and random data."""
    vectors = []
    
    edge_cases_pc = [
        0x00000000, 0x00001000, # Start of memory, Typical instruction start
        0x7FFFFFFC, 0x80000000, # Boundaries (Word aligned)
        0xFFFFFFFC              # Very end of memory
    ]
    
    edge_cases_imm = [
        0x00000000, 0xFFFFFFFF, # 0, -1
        0x00000004, 0xFFFFFFFC, # +4, -4
        0x00000010, 0xFFFFFFF0  # +16, -16
    ]

    for _ in range(num_iterations):
        # 30% chance of Edge Case, 70% chance of Random Vector
        if random.random() < 0.3:
            prev_PC = random.choice(edge_cases_pc)
            imm = random.choice(edge_cases_imm)
            ALU_result = random.choice(edge_cases_pc)
        else:
            prev_PC = random.getrandbits(30) << 2 # Word-aligned random PC
            imm = random.getrandbits(32)
            ALU_result = random.getrandbits(32)

        PC_select = random.randint(0, 3)
        branch_flag = random.choice([0, 1])
        
        # Make stalls relatively infrequent to thoroughly test normal pathways
        # PC_increment = 0 means STALL, PC_increment = 1 means NORMAL INCREMENT
        PC_increment = 0 if random.random() < 0.1 else 1

        new_PC, pc_plus_4, pc_plus_imm = calculate_expected(
            prev_PC, imm, ALU_result, PC_select, branch_flag, PC_increment
        )
        
        # Packing map: 
        # prev_PC[195:164] | imm[163:132] | ALU_result[131:100] | PC_select[99:98] | 
        # branch_flag[97] | PC_increment[96] | new_PC[95:64] | PC_plus_4[63:32] | PC_plus_imm[31:0]
        # Total bits = 32*3 + 2 + 1 + 1 + 32*3 = 196 bits
        
        vector_int = (prev_PC << 164) | (imm << 132) | (ALU_result << 100) | \
                     (PC_select << 98) | (branch_flag << 97) | (PC_increment << 96) | \
                     (new_PC << 64) | (pc_plus_4 << 32) | pc_plus_imm
        
        # 196 bits fits precisely into 49 hex characters
        vectors.append(f"{vector_int:049x}")
        
    return vectors

def get_testbench_code(num_iterations, tv_file):
    """Returns the dynamically generated SV testbench string."""
    return f"""`default_nettype none
`timescale 1ns/1ps

module {MODULE_NAME}_tb;

    // --- Inputs ---
    logic [31:0] prev_PC, imm, ALU_result;
    logic [1:0] PC_select;
    logic branch_flag, PC_increment;

    // --- Outputs ---
    logic [31:0] new_PC, PC_plus_4, PC_plus_imm;

    // --- Verification Variables ---
    logic [31:0] expected_new_PC, expected_PC_plus_4, expected_PC_plus_imm;
    
    // 196 bits wide vector
    logic [195:0] test_vectors [0:{num_iterations - 1}];
    int error_count;
    int i;

    // Instantiate the Unit Under Test (UUT)
    {MODULE_NAME} uut (
        .prev_PC(prev_PC), 
        .imm(imm), 
        .ALU_result(ALU_result),
        .PC_select(PC_select), 
        .branch_flag(branch_flag), 
        .PC_increment(PC_increment),
        .new_PC(new_PC), 
        .PC_plus_4(PC_plus_4), 
        .PC_plus_imm(PC_plus_imm)
    );

    initial begin
        $readmemh("{tv_file}", test_vectors);
        error_count = 0;

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            prev_PC = test_vectors[i][195:164];
            imm = test_vectors[i][163:132];
            ALU_result = test_vectors[i][131:100];
            PC_select = test_vectors[i][99:98];
            branch_flag = test_vectors[i][97];
            PC_increment = test_vectors[i][96];
            
            expected_new_PC = test_vectors[i][95:64];
            expected_PC_plus_4 = test_vectors[i][63:32];
            expected_PC_plus_imm = test_vectors[i][31:0];

            #10; // Logic propagation

            if (new_PC !== expected_new_PC || PC_plus_4 !== expected_PC_plus_4 || PC_plus_imm !== expected_PC_plus_imm) begin
                
                $display("ERROR [Vector %0d] - prev_PC:%08x imm:%08x ALU_res:%08x sel:%0d br:%b inc(stall):%b", 
                         i, prev_PC, imm, ALU_result, PC_select, branch_flag, PC_increment);
                         
                if (new_PC !== expected_new_PC)
                    $display("ERROR        -> NEW_PC      EXPECTED: %08x | GOT: %08x", expected_new_PC, new_PC);
                if (PC_plus_4 !== expected_PC_plus_4)
                    $display("ERROR        -> PC_PLUS_4   EXPECTED: %08x | GOT: %08x", expected_PC_plus_4, PC_plus_4);
                if (PC_plus_imm !== expected_PC_plus_imm)
                    $display("ERROR        -> PC_PLUS_IMM EXPECTED: %08x | GOT: %08x", expected_PC_plus_imm, PC_plus_imm);
                
                error_count++;
            end
        end

        $display("Verification Complete. Total Errors: %0d / %0d\\n", error_count, {num_iterations});
        $finish;
    end
endmodule
"""