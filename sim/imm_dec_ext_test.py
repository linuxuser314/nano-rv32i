#!/usr/bin/env python3
"""
################################################################################
# CREATOR CITATION: Created by Gemini (Google)
#
# SAMPLE PROMPT FOR RECREATION/ADAPTATION:
# "Act as an expert digital verification engineer. Write a Python script that 
# asks the user for a number of test iterations and a test mode (Random, Edge, 
# Mixed) to verify a SystemVerilog module with the following header: 
# `module imm_dec_ext(input logic I, S, B, U, J, input logic [31:7] instruction, 
# output logic [31:0] out);`. The script must mathematically model RISC-V 
# immediate decoding, write the stimuli and expected results to a `.tv` file in 
# hex, and dynamically generate a modern SystemVerilog testbench (`_tb.sv`). 
# The testbench must use `logic`, named port mapping, and `$readmemh`. Use 
# Python's `subprocess` to compile and run using `iverilog` and `vvp`. Provide 
# interactive error handling and log any failures along with the RNG seed to an 
# errors.log file."
################################################################################
"""

import os
import sys
import random
import subprocess
import datetime

# --- MODULE CONSTANTS ---
MODULE_NAME = "imm_dec_ext"
TV_FILE = f"{MODULE_NAME}_vectors.tv"
TB_FILE = f"{MODULE_NAME}_tb.sv"
SIM_OUT = f"{MODULE_NAME}_sim.out"
ERR_LOG = f"{MODULE_NAME}_errors.log"

def sign_extend_to_32(val, bits):
    """Sign-extends a value of 'bits' length to 32 bits."""
    sign_bit = (val >> (bits - 1)) & 1
    if sign_bit:
        mask = (1 << 32) - (1 << bits)
        return val | mask
    else:
        return val

def calculate_expected(instr_type, inst_val):
    """
    Mathematically models the expected RISC-V immediate output.
    instr_type is a string: 'I', 'S', 'B', 'U', or 'J'.
    inst_val is a 32-bit integer.
    """
    if instr_type == 'I':
        imm = (inst_val >> 20) & 0xFFF
        return sign_extend_to_32(imm, 12)
    elif instr_type == 'S':
        imm = (((inst_val >> 25) & 0x7F) << 5) | ((inst_val >> 7) & 0x1F)
        return sign_extend_to_32(imm, 12)
    elif instr_type == 'B':
        b12 = (inst_val >> 31) & 1
        b11 = (inst_val >> 7) & 1
        b10_5 = (inst_val >> 25) & 0x3F
        b4_1 = (inst_val >> 8) & 0xF
        imm = (b12 << 12) | (b11 << 11) | (b10_5 << 5) | (b4_1 << 1)
        return sign_extend_to_32(imm, 13)
    elif instr_type == 'U':
        imm = inst_val & 0xFFFFF000
        return imm # U-Type already padded to 32 bits natively
    elif instr_type == 'J':
        b20 = (inst_val >> 31) & 1
        b19_12 = (inst_val >> 12) & 0xFF
        b11 = (inst_val >> 20) & 1
        b10_1 = (inst_val >> 21) & 0x3FF
        imm = (b20 << 20) | (b19_12 << 12) | (b11 << 11) | (b10_1 << 1)
        return sign_extend_to_32(imm, 21)
    else:
        return 0

def generate_test_vectors(num_iterations, mode):
    """Generates the stimulus and expected results."""
    vectors = []
    types = ['I', 'S', 'B', 'U', 'J']
    
    edge_cases = [
        0x00000000, 0xFFFFFFFF, # All 0s, All 1s
        0x7FFFFFFF, 0x80000000, # Max Pos, Max Neg (testing sign bits)
        0xAAAAAAAA, 0x55555555  # Alternating
    ]

    for _ in range(num_iterations):
        # Determine current mode per iteration
        current_mode = mode
        if mode == 3: # Mixed
            current_mode = 1 if random.random() > 0.3 else 2

        # 1-hot type selection
        instr_type = random.choice(types)
        
        # Instruction generation
        if current_mode == 2:
            inst_val = random.choice(edge_cases)
        else:
            inst_val = random.getrandbits(32)

        expected = calculate_expected(instr_type, inst_val)
        
        # Map variables for TV file formatting
        I_bit = 1 if instr_type == 'I' else 0
        S_bit = 1 if instr_type == 'S' else 0
        B_bit = 1 if instr_type == 'B' else 0
        U_bit = 1 if instr_type == 'U' else 0
        J_bit = 1 if instr_type == 'J' else 0
        
        # Extract the relevant 25 bits [31:7]
        inst_25bit = (inst_val >> 7) & 0x1FFFFFF
        expected_32bit = expected & 0xFFFFFFFF
        
        # Pack into a 62-bit word for easy parsing in SV:
        # 1 bit each for I, S, B, U, J (5) + 25 bit instruction + 32 bit expected = 62 bits
        vector_int = (I_bit << 61) | (S_bit << 60) | (B_bit << 59) | (U_bit << 58) | (J_bit << 57) | (inst_25bit << 32) | expected_32bit
        
        # Format as a 16-character hex string (zero padded)
        vectors.append(f"{vector_int:016x}")
        
    return vectors

def write_testbench(num_iterations):
    """Dynamically generates the SystemVerilog testbench."""
    tb_code = f"""`default_nettype none
`timescale 1ns/1ps

module {MODULE_NAME}_tb;

    // --- Inputs ---
    logic I, S, B, U, J;
    logic [31:7] instruction;

    // --- Outputs ---
    logic [31:0] out;

    // --- Verification Variables ---
    logic [31:0] expected_out;
    logic [61:0] test_vectors [0:{num_iterations - 1}];
    int error_count;
    int i;

    // --- Instantiate the Unit Under Test (UUT) ---
    {MODULE_NAME} uut (
        .I(I),
        .S(S),
        .B(B),
        .U(U),
        .J(J),
        .instruction(instruction),
        .out(out)
    );

    initial begin
        // Load the test vectors
        $readmemh("{TV_FILE}", test_vectors);
        error_count = 0;

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            // Parse vector bits safely
            I = test_vectors[i][61];
            S = test_vectors[i][60];
            B = test_vectors[i][59];
            U = test_vectors[i][58];
            J = test_vectors[i][57];
            instruction = test_vectors[i][56:32];
            expected_out = test_vectors[i][31:0];

            #10; // Wait for combinational logic propagation

            // Flag mismatch
            if (out !== expected_out) begin
                $display("ERROR [Vector %0d] - I:%b S:%b B:%b U:%b J:%b | Inst[31:7]:%06x", 
                         i, I, S, B, U, J, instruction);
                $display("       -> EXPECTED: %08x | GOT: %08x", expected_out, out);
                error_count++;
            end
        end

        $display("Verification Complete. Total Errors: %0d / %0d\\n", error_count, {num_iterations});
        $finish;
    end

endmodule
"""
    with open(TB_FILE, 'w') as f:
        f.write(tb_code)

def main():
    print(f"--- SystemVerilog Test Generator: {MODULE_NAME} ---")
    
    # 1. Check for the SystemVerilog module in the ../rtl directory
    sv_file = f"../rtl/{MODULE_NAME}.sv"
    if not os.path.exists(sv_file):
        print(f"WARNING: '{sv_file}' not found.")
        print(f"Please ensure your RTL file is located at '{sv_file}' before continuing.")
        input("Press Enter once the file is available, or Ctrl+C to abort...")

    # 2. Get user inputs
    try:
        num_iterations = int(input("How many test iterations would you like to run? "))
        print("\nTest Modes:\n  1) Random Vectors\n  2) Edge Cases (0s, 1s, Boundaries)\n  3) Mixed")
        mode = int(input("Select testing mode (1-3): "))
        if mode not in [1, 2, 3]:
            raise ValueError
    except ValueError:
        print("Invalid input. Defaulting to 1000 iterations, Mixed mode.")
        num_iterations = 1000
        mode = 3

    # 3. Initialize RNG and Seed
    seed = random.randrange(sys.maxsize)
    random.seed(seed)
    print(f"\n[INFO] Random Seed generated: {seed}")

    # 4. Generate Vectors & Write files
    print(f"[INFO] Generating {num_iterations} test vectors...")
    vectors = generate_test_vectors(num_iterations, mode)
    
    with open(TV_FILE, 'w') as f:
        for v in vectors:
            f.write(v + '\n')
            
    print(f"[INFO] Writing vectors to {TV_FILE}")
    
    print(f"[INFO] Generating testbench {TB_FILE}...")
    write_testbench(num_iterations)

    # 5. Compile and Simulate using Icarus Verilog
    print("\n[INFO] Compiling via iverilog...")
    compile_cmd = ["iverilog", "-g2012", sv_file, TB_FILE, "-o", SIM_OUT]
    compile_result = subprocess.run(compile_cmd, capture_output=True, text=True)

    if compile_result.returncode != 0:
        print("\n[CRITICAL ERROR] Compilation failed!")
        print(compile_result.stderr)
        sys.exit(1)

    print("[INFO] Simulating via vvp...")
    sim_cmd = ["vvp", SIM_OUT]
    sim_result = subprocess.run(sim_cmd, capture_output=True, text=True)

    # 6. Parse Output & Error Handling
    output_lines = sim_result.stdout.split('\n')
    errors = [line for line in output_lines if line.startswith("ERROR")]
    total_errors_line = next((line for line in output_lines if "Total Errors" in line), None)
    
    if total_errors_line:
        print(f"\n[SIMULATION RESULT] {total_errors_line}")
    else:
        print("\n[SIMULATION ERROR] Could not find completion message. Simulation may have crashed.")
        print(sim_result.stdout)

    if errors:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(ERR_LOG, 'w') as f:
            f.write(f"--- Error Log for {MODULE_NAME} ---\n")
            f.write(f"Date/Time: {timestamp}\n")
            f.write(f"RNG Seed : {seed}\n")
            f.write(f"Mode     : {mode}\n")
            f.write(f"-------------------------------------\n")
            for err in errors:
                f.write(err + '\n')
        
        print(f"[WARNING] {len(errors)} mismatches detected. Details saved to {ERR_LOG}.")
        view_err = input("Would you like to view the errors in the console now? (y/n): ")
        if view_err.lower() == 'y':
            print("-" * 50)
            for err in errors[:50]: # Cap print out at 50 so we don't flood the terminal
                print(err)
            if len(errors) > 50:
                print(f"... and {len(errors) - 50} more. (See {ERR_LOG})")
            print("-" * 50)
    else:
        print("[SUCCESS] All test vectors passed successfully!")

    # 7. Cleanup generated files
    print("\n[INFO] Cleaning up temporary test files...")
    for temp_file in [TV_FILE, TB_FILE, SIM_OUT]:
        if os.path.exists(temp_file):
            os.remove(temp_file)
            print(f"       -> Removed {temp_file}")

if __name__ == "__main__":
    main()