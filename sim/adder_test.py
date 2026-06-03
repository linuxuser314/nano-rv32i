#!/usr/bin/env python3
"""
################################################################################
# CREATOR CITATION: Created by Gemini (Google)
#
# SAMPLE PROMPT FOR RECREATION/ADAPTATION:
# "Act as an expert digital verification engineer. Write a Python script that 
# asks the user for a number of test iterations and a test mode (Random, Edge, 
# Mixed) to verify a SystemVerilog module with the following header: 
# `module adder(input logic[31:0] a, b, input logic cin, output logic[31:0] 
# result, output logic cout);`. The script must mathematically model 32-bit 
# addition with carry-in and carry-out. Write the stimuli and expected results 
# to a `.tv` file in hex, and dynamically generate a modern SystemVerilog testbench 
# (`_tb.sv`). The testbench must use `logic`, named port mapping, and 
# `$readmemh`. Use Python's `subprocess` to compile and run using `iverilog` 
# and `vvp`. Provide interactive error handling and log any failures along with 
# the RNG seed to an errors.log file, then clean up artifacts."
################################################################################
"""

import os
import sys
import random
import subprocess
import datetime

# --- MODULE CONSTANTS ---
MODULE_NAME = "adder"
TV_FILE = f"{MODULE_NAME}_vectors.tv"
TB_FILE = f"{MODULE_NAME}_tb.sv"
SIM_OUT = f"{MODULE_NAME}_sim.out"
ERR_LOG = f"{MODULE_NAME}_errors.log"

def calculate_expected(a, b, cin):
    """
    Mathematically models the expected adder result and carry-out.
    a, b: 32-bit unsigned integers
    cin: 0 or 1 integer
    """
    total = a + b + cin
    result = total & 0xFFFFFFFF
    cout = (total >> 32) & 1
    
    return result, cout

def generate_test_vectors(num_iterations, mode):
    """Generates the stimulus and expected results."""
    vectors = []
    
    edge_cases = [
        0x00000000, 0xFFFFFFFF, # All 0s, All 1s (-1)
        0x7FFFFFFF, 0x80000000, # Max Pos, Max Neg
        0xAAAAAAAA, 0x55555555, # Alternating
        0x00000001, 0xFFFFFFFE  # 1, -2
    ]

    for _ in range(num_iterations):
        current_mode = mode
        if mode == 3: # Mixed
            current_mode = 1 if random.random() > 0.4 else 2

        # Generate inputs a, b, and cin
        if current_mode == 2:
            a = random.choice(edge_cases)
            b = random.choice(edge_cases)
        else:
            a = random.getrandbits(32)
            b = random.getrandbits(32)
            
        cin = random.choice([0, 1])

        # Get expected outputs
        result, cout = calculate_expected(a, b, cin)
        
        # Map variables for TV file formatting into a single 98-bit integer:
        # a[97:66] | b[65:34] | cin[33] | result[32:1] | cout[0]
        vector_int = (a << 66) | (b << 34) | (cin << 33) | (result << 1) | cout
        
        # Format as a 25-character hex string (zero padded for 100 bits to cover 98 bits)
        vectors.append(f"{vector_int:025x}")
        
    return vectors

def write_testbench(num_iterations):
    """Dynamically generates the SystemVerilog testbench."""
    tb_code = f"""`default_nettype none
`timescale 1ns/1ps

module {MODULE_NAME}_tb;

    // --- Inputs ---
    logic [31:0] a, b;
    logic cin;

    // --- Outputs ---
    logic [31:0] result;
    logic cout;

    // --- Verification Variables ---
    logic [31:0] expected_result;
    logic expected_cout;
    
    // 98 bits total wide TV vector
    logic [97:0] test_vectors [0:{num_iterations - 1}];
    int error_count;
    int i;

    // --- Instantiate the Unit Under Test (UUT) ---
    {MODULE_NAME} uut (
        .a(a),
        .b(b),
        .cin(cin),
        .result(result),
        .cout(cout)
    );

    initial begin
        // Load the test vectors
        $readmemh("{TV_FILE}", test_vectors);
        error_count = 0;

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            // Parse vector bits safely
            a = test_vectors[i][97:66];
            b = test_vectors[i][65:34];
            cin = test_vectors[i][33];
            
            expected_result = test_vectors[i][32:1];
            expected_cout = test_vectors[i][0];

            #10; // Wait for combinational logic propagation

            // Flag mismatch
            if (result !== expected_result || cout !== expected_cout) begin
                $display("ERROR [Vector %0d] - a:%08x b:%08x cin:%b", 
                         i, a, b, cin);
                         
                if (result !== expected_result) begin
                    $display("ERROR        -> RESULT EXPECTED: %08x | GOT: %08x", expected_result, result);
                end
                if (cout !== expected_cout) begin
                    $display("ERROR        -> COUT   EXPECTED: %b | GOT: %b", expected_cout, cout);
                end
                
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
    # Kept "-y", "../rtl" and "-Y", ".sv" in case your adder relies on lower level submodules (e.g. full_adder.sv)
    compile_cmd = ["iverilog", "-g2012", "-y", "../rtl", "-Y", ".sv", sv_file, TB_FILE, "-o", SIM_OUT]
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