`default_nettype wire//AI said this would fix the formal verificaiton problems that symbiyosys was choking on about my syntax and stuff... Worth a shot I suppose!

module rvfi_wrapper(

    //Basic required system IO
    input  logic        clock,
    input  logic        reset,

    //Instruction metadata
    output logic       rvfi_valid,
    output logic[63:0] rvfi_order,
    output logic[31:0] rvfi_insn,
    output logic       rvfi_trap,
    output logic       rvfi_halt,
    output logic       rvfi_intr,
    output logic[1:0]  rvfi_mode,
    output logic[1:0]  rvfi_ixl,

    //Integer register read
    output logic[4:0]  rvfi_rs1_addr,
    output logic[4:0]  rvfi_rs2_addr,
    output logic[31:0] rvfi_rs1_rdata,
    output logic[31:0] rvfi_rs2_rdata,

    //Integer register write
    output logic[4:0]  rvfi_rd_addr,
    output logic[31:0] rvfi_rd_wdata,

    //Program counter
    output logic[31:0] rvfi_pc_rdata,
    output logic[31:0] rvfi_pc_wdata,

    //Memory accesses
    output logic[31:0] rvfi_mem_addr,
    output logic[3:0]  rvfi_mem_rmask,
    output logic[3:0]  rvfi_mem_wmask,
    output logic[31:0] rvfi_mem_rdata,
    output logic[31:0] rvfi_mem_wdata,

    //Unconstrained memory IO
    input  logic[31:0] unconstrained_fetch_data,
    input  logic[31:0] unconstrained_read_data
);
    logic fault_stall; 
    assign rvfi_trap = dut.FAULT;

    //Have to do some gynmastics here so that it asserts the valid signal with the halt and trap signals whenever a wait state occurs...
    //assign rvfi_valid = ~(dut.previous_cycle_was_start_of_load || fault_stall) || (dut.FAULT && dut.previous_cycle_was_start_of_load);
    //That line worked for liveness but caused loads to fail...)

    //This should be the corrected version.

    //We need to retire normal instructions correctly. Loads need to wait a cycle UNLESS they are misaligned.
    //Faults need to stop retirement after the cycle on which they occur.
    always_comb begin

        if(fault_stall) begin
            rvfi_valid = '0;
        end
        else if(dut.previous_cycle_was_start_of_load) begin
            rvfi_valid = '0;
            if(rvfi_trap) begin
                rvfi_valid = 1'b1;
            end
        end
        else begin
            rvfi_valid = 1'b1;
        end

    end
    always_ff @(posedge clock) begin
        if(reset) begin
            fault_stall <= '0;
        end
        else if(dut.FAULT) begin
            fault_stall <= 1'b1;
        end
    end
    logic[31:0] old_unconstrained_fetch_data;

    dff_register #(
        .SIZE(32)
    ) unconstrained_instruction_register (
        .clk(clock), .reset(reset), .en(1'b1),
        .din(unconstrained_fetch_data),
        .dout(old_unconstrained_fetch_data)
    );

    assign rvfi_insn = dut.instruction;
   
    assign fetch_bus.read_data = dut.current_cycle_is_end_of_load ? old_unconstrained_fetch_data : unconstrained_fetch_data;

    //Does not have a WFI or internal power-down state
    assign rvfi_halt = fault_stall | dut.FAULT;//Should be fixed now...
    //Does not support interrupts
    assign rvfi_intr = '0;
    //Machine mode only
    assign rvfi_mode = 2'b11;
    //32-bit instructions
    assign rvfi_ixl  = 2'b01;

    assign rvfi_mem_addr  = data_bus.address;
    assign rvfi_mem_rmask = dut.main_memory_unit.read_rmask_rvfi;
    assign rvfi_mem_wmask = data_bus.write_enable ? data_bus.write_enable_control : '0;
    assign rvfi_mem_rdata = unconstrained_read_data;
    assign rvfi_mem_wdata = data_bus.write_data;

    assign data_bus.read_data = unconstrained_read_data;

    ram_bus_if fetch_bus();
    ram_bus_if data_bus();

    rv32i_core dut(
        .clk(clock),
        .reset(reset),

        .DATA_FAULT('0),
        .FETCH_FAULT('0),
        .fetch_bus(fetch_bus),
        .data_bus(data_bus)
    );

    //Only thing needed for fetch bus (all core outputs just stream out into the void).

    //Register read bindings
    assign rvfi_rs1_addr = dut.instruction[19:15];
    assign rvfi_rs2_addr = dut.instruction[24:20];
    assign rvfi_rs1_rdata = dut.RF_rd1;
    assign rvfi_rs2_rdata = dut.RF_rd2;

    //Register write bindings
    logic write_enable;
    assign write_enable = dut.RF_write_enable && (dut.instruction[11:7] != 5'b0);
    assign rvfi_rd_addr = write_enable ? dut.instruction[11:7] : '0;
    assign rvfi_rd_wdata = write_enable ? dut.result_mux_out : '0;

    //PC bindings
    assign rvfi_pc_rdata = dut.prev_PC;
    assign rvfi_pc_wdata = dut.PC_result;

    //In-order single-issue core increments by 1 every time rvfi_valid is high   
    always_ff @(posedge clock) begin
        if(reset) begin
            rvfi_order <= '0;
        end
        else if(rvfi_valid) begin
            rvfi_order <= rvfi_order + 1;
        end
    end

endmodule