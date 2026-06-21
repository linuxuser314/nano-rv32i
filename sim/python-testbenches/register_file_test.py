import random

# Expose module name to the master controller
MODULE_NAME = "register_file"

def generate_vectors(num_iterations):
    """
    Generates stimulus for the register file.
    Because this is a sequential module, Python must maintain state across iterations.
    """
    vectors = []
    
    # Internal Python state representing the 32 registers (for a 5-bit address space)
    regs = [0] * 32
    
    edge_cases_data = [
        0x00000000, 0xFFFFFFFF, 
        0x7FFFFFFF, 0x80000000,
        0xAAAAAAAA, 0x55555555
    ]

    for i in range(num_iterations):
        # 1. Generate random inputs for this clock cycle
        
        # Force a reset on the very first cycle, and a 2% chance afterwards
        reset = 1 if (i == 0 or random.random() < 0.02) else 0
        
        # 70% chance to write data. 
        # Crucial change: write_enable is generated independently of reset 
        # to explicitly test reset-over-write priority.
        write_enable = 1 if (random.random() < 0.7) else 0
        
        a1 = random.randint(0, 31)
        a2 = random.randint(0, 31)
        a3 = random.randint(0, 31)
        
        if random.random() < 0.3:
            wd3 = random.choice(edge_cases_data)
        else:
            wd3 = random.getrandbits(32)

        # 2. Compute expected combinational asynchronous reads (BEFORE the clock edge)
        # Register 0 is hardwired to 0. 
        # If reset is active, asynchronous resets immediately clear the outputs.
        if reset:
            exp_rd1 = 0
            exp_rd2 = 0
        else:
            exp_rd1 = 0 if a1 == 0 else regs[a1]
            exp_rd2 = 0 if a2 == 0 else regs[a2]

        # 3. Pack the vector
        # Packing map:
        # reset[112] | write_enable[111] | a1[110:106] | a2[105:101] | a3[100:96] |
        # wd3[95:64] | exp_rd1[63:32] | exp_rd2[31:0]
        # Total bits = 1 + 1 + 5 + 5 + 5 + 32 + 32 + 32 = 113 bits
        
        vector_int = (reset << 112) | (write_enable << 111) | (a1 << 106) | \
                     (a2 << 101) | (a3 << 96) | (wd3 << 64) | \
                     (exp_rd1 << 32) | exp_rd2
                     
        # 113 bits fits into 29 hex characters
        vectors.append(f"{vector_int:029x}")
        
        # 4. Simulate the POSITIVE CLOCK EDGE (Updates state for the NEXT iteration)
        # Note: 'reset' takes absolute priority here, mirroring the hardware specification.
        if reset:
            regs = [0] * 32
        elif write_enable and a3 != 0:
            regs[a3] = wd3
            
    return vectors

def get_testbench_code(num_iterations, tv_file):
    """Returns the dynamically generated SV testbench string."""
    return f"""`default_nettype none
`timescale 1ns/1ps

module {MODULE_NAME}_tb;

    // --- Inputs ---
    logic clk, reset, write_enable;
    logic [4:0] a1, a2, a3;
    logic [31:0] wd3;

    // --- Outputs ---
    logic [31:0] rd1, rd2;

    // --- Verification Variables ---
    logic [31:0] expected_rd1, expected_rd2;
    
    // 113 bits wide vector
    logic [112:0] test_vectors [0:{num_iterations - 1}];
    int error_count;
    int i;

    // Instantiate the Unit Under Test (UUT)
    {MODULE_NAME} uut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .a1(a1), .a2(a2), .a3(a3),
        .wd3(wd3),
        .rd1(rd1), .rd2(rd2)
    );

    initial begin
        $readmemh("{tv_file}", test_vectors);
        error_count = 0;
        clk = 0;

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            // 1. Apply inputs
            reset = test_vectors[i][112];
            write_enable = test_vectors[i][111];
            a1 = test_vectors[i][110:106];
            a2 = test_vectors[i][105:101];
            a3 = test_vectors[i][100:96];
            wd3 = test_vectors[i][95:64];
            
            expected_rd1 = test_vectors[i][63:32];
            expected_rd2 = test_vectors[i][31:0];

            // 2. Wait a moment for asynchronous read logic to settle
            #1; 

            // 3. Verify outputs BEFORE the clock edge changes the state
            if (rd1 !== expected_rd1 || rd2 !== expected_rd2) begin
                $display("ERROR [Cycle %0d] - rst:%b we:%b a1:%0d a2:%0d a3:%0d wd3:%08x", 
                         i, reset, write_enable, a1, a2, a3, wd3);
                         
                if (rd1 !== expected_rd1)
                    $display("ERROR        -> RD1 EXPECTED: %08x | GOT: %08x", expected_rd1, rd1);
                if (rd2 !== expected_rd2)
                    $display("ERROR        -> RD2 EXPECTED: %08x | GOT: %08x", expected_rd2, rd2);
                
                error_count++;
            end

            // 4. Manual Clock Pulse to commit writes for the next iteration
            #4; clk = 1;
            #5; clk = 0;
        end

        $display("Verification Complete. Total Errors: %0d / %0d\\n", error_count, {num_iterations});
        $finish;
    end
endmodule
"""