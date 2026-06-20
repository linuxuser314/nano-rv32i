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
    Generates stimulus for the memory subsystem matching single-cycle architecture.
    
    Timing Model:
    - Stores: Address/data presented on cycle i, committed on posedge i, readable on cycle i+1
    - Loads: TWO-CYCLE operation with automatic pairing:
      * Cycle i (Address): Address latches on posedge, is_byte/is_half/is_unsigned used
      * Cycle i+1 (Writeback): Same control signals re-applied, data read on posedge i,
                                shifted/masked/extended combinationally, written to RF on posedge i+1
    - Instruction Fetch: Dual-port BRAM, data available combinationally after posedge
    
    The generator automatically inserts a writeback cycle after every load address cycle.
    """
    vectors = []
    
    # Virtual byte-addressable memory
    virtual_mem = {}
    
    # State from previous cycle (what gets output THIS cycle)
    prev_instruction = 0
    prev_load_result = 0
    
    # For tracking load address stage to generate writeback automatically
    pending_load_writeback = False
    pending_load_addr = 0
    pending_load_is_byte = False
    pending_load_is_half = False
    pending_load_is_unsigned = False
    pending_PC = 0

    for i in range(num_iterations):
        # ===== Check if this cycle is a load writeback (automatically inserted) =====
        if pending_load_writeback:
            # This cycle: Load Writeback Stage
            is_byte = pending_load_is_byte
            is_half = pending_load_is_half
            is_unsigned = pending_load_is_unsigned
            is_store = 0
            
            # Data was latched from memory on previous posedge, now shift/mask/extend
            load_addr = pending_load_addr
            load_misaligned = 0
            if not is_byte:
                if is_half and (load_addr % 2 != 0):
                    load_misaligned = 1
                elif (not is_half) and (load_addr % 4 != 0):
                    load_misaligned = 1
            
            access_size = 1 if is_byte else (2 if is_half else 4)
            load_oob = 1 if (load_addr < 0 or load_addr + (access_size - 1) >= MEM_SIZE) else 0
            
            # Extract loaded data from memory
            if not load_misaligned and not load_oob:
                if is_byte:
                    val = get_byte(virtual_mem, load_addr)
                    if not is_unsigned and (val & 0x80):
                        load_result = val | 0xFFFFFF00
                    else:
                        load_result = val
                elif is_half:
                    val = get_byte(virtual_mem, load_addr) | (get_byte(virtual_mem, load_addr + 1) << 8)
                    if not is_unsigned and (val & 0x8000):
                        load_result = val | 0xFFFF0000
                    else:
                        load_result = val
                else:  # Word
                    b0 = get_byte(virtual_mem, load_addr)
                    b1 = get_byte(virtual_mem, load_addr + 1)
                    b2 = get_byte(virtual_mem, load_addr + 2)
                    b3 = get_byte(virtual_mem, load_addr + 3)
                    load_result = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
            else:
                load_result = 0
            
            # On writeback cycle, PC advances (PC_increment = 1)
            PC = pending_PC
            addr = pending_load_addr  # Keep same address (though not used)
            store_data = 0
            
            # Error flags
            exp_inst_misaligned = 0
            exp_inst_oob = 0
            exp_mem_misaligned = load_misaligned
            exp_mem_oob = load_oob
            
            # Outputs visible THIS cycle come from PREVIOUS cycle
            exp_instruction = prev_instruction
            exp_load_result = prev_load_result
            
            # Clear pending writeback
            pending_load_writeback = False
            
        else:
            # Normal execution cycle
            is_byte = random.choice([0, 1])
            is_half = 0 if is_byte else random.choice([0, 1])  # Mutually exclusive
            is_unsigned = random.choice([0, 1])
            
            # 40% chance of store, otherwise load or other op
            is_store = 1 if (random.random() < 0.4) else 0
            
            # 2. Generate PC and addr (combinationally available)
            stim_type = random.random()
            
            if stim_type < 0.15:
                # Misaligned PC
                PC = (random.randint(0, MEM_SIZE - 4) & ~3) + random.randint(1, 3)
                addr = random.randint(0, MEM_SIZE - 1)
            elif stim_type < 0.30:
                # OOB addresses
                PC = random.randint(MEM_SIZE, MEM_SIZE + 100)
                addr = random.randint(MEM_SIZE, MEM_SIZE + 100)
            else:
                # Normal aligned accesses
                PC = random.randint(0, (MEM_SIZE - 4) // 4) * 4
                if is_half:
                    addr = random.randint(0, (MEM_SIZE - 2) // 2) * 2
                elif is_byte:
                    addr = random.randint(0, MEM_SIZE - 1)
                else:
                    addr = random.randint(0, (MEM_SIZE - 4) // 4) * 4
            
            store_data = random.getrandbits(32)
            
            # 3. Check instruction address
            inst_misaligned = 1 if (PC % 4 != 0) else 0
            inst_oob = 1 if (PC < 0 or PC + 3 >= MEM_SIZE) else 0
            
            # 4. Check data address (if load or store)
            mem_misaligned = 0
            if not is_byte:
                if is_half and (addr % 2 != 0):
                    mem_misaligned = 1
                elif (not is_half) and (addr % 4 != 0):
                    mem_misaligned = 1
            
            access_size = 1 if is_byte else (2 if is_half else 4)
            mem_oob = 1 if (addr < 0 or addr + (access_size - 1) >= MEM_SIZE) else 0
            
            # 5. Get combinational instruction data (from previous PC read)
            next_instruction = 0
            if not inst_misaligned and not inst_oob:
                b0 = get_byte(virtual_mem, PC)
                b1 = get_byte(virtual_mem, PC + 1)
                b2 = get_byte(virtual_mem, PC + 2)
                b3 = get_byte(virtual_mem, PC + 3)
                next_instruction = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
            
            # 6. Outputs visible THIS cycle are from PREVIOUS cycle
            exp_instruction = prev_instruction
            exp_load_result = prev_load_result
            exp_inst_misaligned = inst_misaligned
            exp_inst_oob = inst_oob
            exp_mem_misaligned = mem_misaligned
            exp_mem_oob = mem_oob
            
            # 7. Determine what happens on THIS cycle's posedge
            if is_store and not mem_misaligned and not mem_oob:
                # Store commits immediately on posedge
                if is_byte:
                    set_byte(virtual_mem, addr, store_data)
                elif is_half:
                    set_byte(virtual_mem, addr, store_data)
                    set_byte(virtual_mem, addr + 1, store_data >> 8)
                else:  # Word
                    set_byte(virtual_mem, addr, store_data)
                    set_byte(virtual_mem, addr + 1, store_data >> 8)
                    set_byte(virtual_mem, addr + 2, store_data >> 16)
                    set_byte(virtual_mem, addr + 3, store_data >> 24)
            
            elif (is_byte or is_half) and not is_store:
                # Load: address latches on posedge
                # Schedule automatic writeback for next cycle
                pending_load_writeback = True
                pending_load_addr = addr
                pending_load_is_byte = is_byte
                pending_load_is_half = is_half
                pending_load_is_unsigned = is_unsigned
                pending_PC = PC + 4  # PC advances on writeback cycle
            
            # 8. Update pipeline state for next cycle
            prev_instruction = next_instruction
            prev_load_result = 0  # Only updates during load writeback

        # ===== Pack Vector =====
        # Bits layout:
        # [196] is_byte
        # [195] is_half
        # [194] is_unsigned
        # [193] is_store
        # [192:161] PC
        # [160:129] addr
        # [128:97] store_data
        # [96:65] exp_instruction
        # [64:33] exp_load_result
        # [32] exp_mem_misaligned
        # [31] exp_inst_misaligned
        # [30] exp_mem_oob
        # [29] exp_inst_oob
        
        vector_int = (is_byte << 196) | (is_half << 195) | (is_unsigned << 194) | (is_store << 193) | \
                     (PC << 161) | (addr << 129) | (store_data << 97) | \
                     (exp_instruction << 65) | (exp_load_result << 33) | \
                     (exp_mem_misaligned << 32) | (exp_inst_misaligned << 31) | \
                     (exp_mem_oob << 30) | (exp_inst_oob << 29)
        
        # Fit in 197 bits (50 hex chars = 200 bits, we use 197)
        vectors.append(f"{vector_int:050x}")

    return vectors

def get_testbench_code(num_iterations, tv_file):
    """Returns the dynamically generated SV testbench for single-cycle architecture."""
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
    logic expected_mem_misaligned, expected_inst_misaligned, expected_mem_oob, expected_inst_oob;
    
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
        #15; 

        $display("\\nStarting Verification of {MODULE_NAME}...");

        for (i = 0; i < {num_iterations}; i++) begin
            // 1. Extract test vector
            is_byte = test_vectors[i][196];
            is_half = test_vectors[i][195];
            is_unsigned = test_vectors[i][194];
            is_store = test_vectors[i][193];
            PC = test_vectors[i][192:161];
            addr = test_vectors[i][160:129];
            store_data = test_vectors[i][128:97];
            
            expected_instruction = test_vectors[i][96:65];
            expected_load_result = test_vectors[i][64:33];
            expected_mem_misaligned = test_vectors[i][32];
            expected_inst_misaligned = test_vectors[i][31];
            expected_mem_oob = test_vectors[i][30];
            expected_inst_oob = test_vectors[i][29];

            // 2. Setup Time: Wait 1ns for inputs to stabilize
            #1; 

            // 3. Clock pulse
            clk = 1;
            #5; 
            clk = 0;
            #4;

            // 4. Verify outputs (skip first cycle as outputs are undefined)
            if (i > 0) begin
                if (instruction !== expected_instruction || 
                    load_result !== expected_load_result || 
                    MEMORY_MISALIGNED_ERROR !== expected_mem_misaligned || 
                    INSTRUCTION_MISALIGNED_ERROR !== expected_inst_misaligned || 
                    MEMORY_OUT_OF_BOUNDS_ERROR !== expected_mem_oob) begin
                    
                    $display("ERROR [Cycle %0d] - PC:%08x addr:%08x op:%s (b:%b h:%b u:%b)", 
                             i, PC, addr, is_store ? "STORE" : "LOAD", 
                             is_byte, is_half, is_unsigned);
                             
                    if (instruction !== expected_instruction)
                        $display("ERROR        -> INSTR EXPECTED: %08x | GOT: %08x", expected_instruction, instruction);
                    if (load_result !== expected_load_result)
                        $display("ERROR        -> LOAD  EXPECTED: %08x | GOT: %08x", expected_load_result, load_result);
                    if (MEMORY_MISALIGNED_ERROR !== expected_mem_misaligned)
                        $display("ERROR        -> MEM_ALIGN EXPECTED: %b | GOT: %b", expected_mem_misaligned, MEMORY_MISALIGNED_ERROR);
                    if (INSTRUCTION_MISALIGNED_ERROR !== expected_inst_misaligned)
                        $display("ERROR        -> INST_ALIGN EXPECTED: %b | GOT: %b", expected_inst_misaligned, INSTRUCTION_MISALIGNED_ERROR);
                    if (MEMORY_OUT_OF_BOUNDS_ERROR !== expected_mem_oob)
                        $display("ERROR        -> OOB EXPECTED: %b | GOT: %b", expected_mem_oob, MEMORY_OUT_OF_BOUNDS_ERROR);
                    
                    error_count++;
                end
            end
        end

        $display("Verification Complete. Total Errors: %0d / %0d\\n", error_count, {num_iterations});
        $finish;
    end
endmodule
"""
