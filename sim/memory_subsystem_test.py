import random

# Expose module name to the master controller
MODULE_NAME = "memory_subsystem"

# Memory Configuration (2304 bytes total = 576 words)
MEM_SIZE = 2304

def get_byte(mem, addr):
    """Safely retrieves a byte from virtual memory. Defaults to 0 if unwritten."""
    return mem.get(addr, 0)

def set_byte(mem, addr, val):
    """Safely sets a byte in virtual memory if within bounds."""
    if 0 <= addr < MEM_SIZE:
        mem[addr] = val & 0xFF

def generate_vectors(num_iterations):
    """
    Generates stimulus for the memory subsystem.
    Python acts as a cycle-accurate golden memory model with 1-cycle read latency.
    """
    vectors = []
    
    # Simple virtual byte-addressable memory state
    # Starts empty, mirroring the hardware's 'initial' block zero-initialization
    virtual_mem = {}

    # State tracking for 1-cycle pipeline delay
    # BRAM registers capture and hold the output of the cycle BEFORE.
    pipeline_instruction = 0
    pipeline_load_result = 0

    for i in range(num_iterations):
        # 1. Initialize Control signals
        is_byte = random.choice([0, 1])
        is_half = 0 if is_byte else random.choice([0, 1]) # Mutually exclusive widths
        is_unsigned = random.choice([0, 1])
        is_store = 1 if (random.random() < 0.4) else 0

        # 2. Pick Address / PC Stimulus (Mix of edge cases and alignment errors)
        # Avoid generating extreme OOB values that poison your array registers with 'x'
        stim_type = random.random()
        
        if stim_type < 0.20:
            # Generate misalignment addresses within range (0 to 2303)
            PC = (random.randint(0, MEM_SIZE - 4) & ~3) + random.randint(1, 3) # Misaligned PC
            addr = random.randint(0, MEM_SIZE - 4)
        else:
            # Normal in-bounds aligned accesses
            PC = random.randint(0, (MEM_SIZE - 4) // 4) * 4
            if is_half:
                addr = random.randint(0, (MEM_SIZE - 2) // 2) * 2
            elif is_byte:
                addr = random.randint(0, MEM_SIZE - 1)
            else:
                addr = random.randint(0, (MEM_SIZE - 4) // 4) * 4

        store_data = random.getrandbits(32)

        # 3. Mathematically model the expected outcomes for the CURRENT request
        inst_misaligned = 1 if (PC % 4 != 0) else 0
        inst_oob = 1 if (PC < 0 or PC + 3 >= MEM_SIZE) else 0
        
        mem_misaligned = 0
        if not is_byte:
            if is_half and (addr % 2 != 0):
                mem_misaligned = 1
            elif (not is_half) and (addr % 4 != 0):
                mem_misaligned = 1
                
        access_size = 1 if is_byte else (2 if is_half else 4)
        mem_oob = 1 if (addr < 0 or addr + (access_size - 1) >= MEM_SIZE) else 0

        # Expected error output lines (Combinational - no clock delay)
        exp_inst_error = inst_misaligned
        exp_mem_error = mem_misaligned
        exp_oob_error = inst_oob or mem_oob

        # Compute Asynchronous Instruction Fetch target (will commit to register on next clk)
        next_instruction = 0
        if not inst_misaligned and not inst_oob:
            b0 = get_byte(virtual_mem, PC)
            b1 = get_byte(virtual_mem, PC + 1)
            b2 = get_byte(virtual_mem, PC + 2)
            b3 = get_byte(virtual_mem, PC + 3)
            next_instruction = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

        # Compute Asynchronous Data Load target (will commit to register on next clk)
        next_load_result = 0
        if not is_store and not mem_misaligned and not mem_oob:
            if is_byte:
                val = get_byte(virtual_mem, addr)
                if not is_unsigned and (val & 0x80):
                    next_load_result = val | 0xFFFFFF00
                else:
                    next_load_result = val
            elif is_half:
                val = get_byte(virtual_mem, addr) | (get_byte(virtual_mem, addr + 1) << 8)
                if not is_unsigned and (val & 0x8000):
                    next_load_result = val | 0xFFFF0000
                else:
                    next_load_result = val
            else: # Word
                b0 = get_byte(virtual_mem, addr)
                b1 = get_byte(virtual_mem, addr + 1)
                b2 = get_byte(virtual_mem, addr + 2)
                b3 = get_byte(virtual_mem, addr + 3)
                next_load_result = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

        # --- PIPELINE SHIFT ---
        # The outputs visible right now are the results of the pipeline_ registers
        # from the PREVIOUS cycle's reads.
        exp_instruction = pipeline_instruction
        exp_load_result = pipeline_load_result

        # Update the pipeline state registers with the newly addressed data
        # for the next cycle.
        pipeline_instruction = next_instruction
        pipeline_load_result = next_load_result

        # 4. Pack vector
        # Packing layout:
        # is_byte[196] | is_half[195] | is_unsigned[194] | is_store[193] |
        # PC[192:161] | addr[160:129] | store_data[128:97] |
        # exp_instruction[96:65] | exp_load_result[64:33] |
        # exp_mem_err[32] | exp_inst_err[31] | exp_oob_err[30]
        vector_int = (is_byte << 196) | (is_half << 195) | (is_unsigned << 194) | (is_store << 193) | \
                     (PC << 161) | (addr << 129) | (store_data << 97) | \
                     (exp_instruction << 65) | (exp_load_result << 33) | \
                     (exp_mem_error << 32) | (exp_inst_error << 31) | (exp_oob_error << 30)

        # 200 bits fits into exactly 50 hex characters
        vectors.append(f"{vector_int:050x}")

        # 5. Simulate store state updates on POSITIVE CLOCK EDGE (for the next cycle)
        if is_store and not mem_misaligned and not mem_oob:
            if is_byte:
                set_byte(virtual_mem, addr, store_data)
            elif is_half:
                set_byte(virtual_mem, addr, store_data)
                set_byte(virtual_mem, addr + 1, store_data >> 8)
            else: # Word
                set_byte(virtual_mem, addr, store_data)
                set_byte(virtual_mem, addr + 1, store_data >> 8)
                set_byte(virtual_mem, addr + 2, store_data >> 16)
                set_byte(virtual_mem, addr + 3, store_data >> 24)

    return vectors

def get_testbench_code(num_iterations, tv_file):
    """Returns the dynamically generated SV testbench string with pipeline synchronization."""
    return f"""`default_nettype none
`timescale 1ns/1ps

module {MODULE_NAME}_tb;

    // --- Inputs ---
    logic [31:0] PC, addr, store_data;
    logic is_half, is_byte, is_unsigned, is_store;
    logic clk;

    // --- Outputs ---
    logic [31:0] load_result, instruction;
    logic MEMORY_MISALIGNED_ERROR, INSTRUCTION_MISALIGNED_ERROR, MEMORY_OUT_OF_BOUNDS_ERROR;

    // --- Verification Variables ---
    logic [31:0] expected_instruction, expected_load_result;
    logic expected_mem_error, expected_inst_error, expected_oob_error;
    
    // 200 bits wide vector
    logic [199:0] test_vectors [0:{num_iterations - 1}];
    int error_count;
    int i;

    // Instantiate the Unit Under Test (UUT)
    {MODULE_NAME} uut (
        .PC(PC), .addr(addr), .store_data(store_data),
        .is_half(is_half), .is_byte(is_byte), .is_unsigned(is_unsigned), .is_store(is_store),
        .clk(clk),
        .load_result(load_result), .instruction(instruction),
        .MEMORY_MISALIGNED_ERROR(MEMORY_MISALIGNED_ERROR),
        .INSTRUCTION_MISALIGNED_ERROR(INSTRUCTION_MISALIGNED_ERROR),
        .MEMORY_OUT_OF_BOUNDS_ERROR(MEMORY_OUT_OF_BOUNDS_ERROR)
    );

    initial begin
        $readmemh("{tv_file}", test_vectors);
        error_count = 0;
        clk = 0;
        
        // --- POWER-ON SEQUENCE ---
        // Allow initial blocks in the RTL to initialize memory to 0
        // before verification checks start.
        #15; 

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            // 1. Apply inputs for the CURRENT cycle
            is_byte = test_vectors[i][196];
            is_half = test_vectors[i][195];
            is_unsigned = test_vectors[i][194];
            is_store = test_vectors[i][193];
            PC = test_vectors[i][192:161];
            addr = test_vectors[i][160:129];
            store_data = test_vectors[i][128:97];
            
            expected_instruction = test_vectors[i][96:65];
            expected_load_result = test_vectors[i][64:33];
            expected_mem_error = test_vectors[i][32];
            expected_inst_error = test_vectors[i][31];
            expected_oob_error = test_vectors[i][30];

            // 2. Setup Time: Wait 1ns for inputs to stabilize on the pins before the clock rises
            #1; 

            // 3. Strobe the clock edge high, then low
            // This propagates our newly applied addresses into the registers uut.system_ram.RD1/RD2
            clk = 1;
            #5; 
            clk = 0;
            #4; // Complete the remainder of the 10ns clock cycle

            // 4. Verify outputs against expected values right now (which represent the latency shifted cycle)
            // Note: Since we are in a 1-cycle latency pipeline, we ignore verifying read data on Cycle 0
            // as its output depends on uninitialized pre-execution memory addresses.
            if (i > 0) begin
                if (instruction !== expected_instruction || 
                    (!is_store && load_result !== expected_load_result) || 
                    MEMORY_MISALIGNED_ERROR !== expected_mem_error || 
                    INSTRUCTION_MISALIGNED_ERROR !== expected_inst_error || 
                    MEMORY_OUT_OF_BOUNDS_ERROR !== expected_oob_error) begin
                    
                    $display("ERROR [Cycle %0d] - PC:%08x addr:%08x op:%s (b:%b h:%b u:%b)", 
                             i, PC, addr, is_store ? "STORE" : "LOAD", is_byte, is_half, is_unsigned);
                             
                    if (instruction !== expected_instruction)
                        $display("ERROR        -> INSTR EXPECTED: %08x | GOT: %08x", expected_instruction, instruction);
                    if (!is_store && load_result !== expected_load_result)
                        $display("ERROR        -> LOAD  EXPECTED: %08x | GOT: %08x", expected_load_result, load_result);
                    if (MEMORY_MISALIGNED_ERROR !== expected_mem_error)
                        $display("ERROR        -> MEM_ALIGN EXPECTED: %b | GOT: %b", expected_mem_error, MEMORY_MISALIGNED_ERROR);
                    if (INSTRUCTION_MISALIGNED_ERROR !== expected_inst_error)
                        $display("ERROR        -> INST_ALIGN EXPECTED: %b | GOT: %b", expected_inst_error, INSTRUCTION_MISALIGNED_ERROR);
                    if (MEMORY_OUT_OF_BOUNDS_ERROR !== expected_oob_error)
                        $display("ERROR        -> OOB EXPECTED: %b | GOT: %b", expected_oob_error, MEMORY_OUT_OF_BOUNDS_ERROR);
                    
                    error_count++;
                end
            end
        end

        $display("Verification Complete. Total Errors: %0d / %0d\\n", error_count, {num_iterations});
        $finish;
    end
endmodule
"""