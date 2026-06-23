`default_nettype none
`timescale 1ns/1ps

module datapath_tb;
    logic clk, reset_active_low;
    logic[5:0] led;

    // Instantiate the datapath
    datapath dut(
        .clk(clk),
        .reset_active_low(reset_active_low),
        .led(led)
    );

    initial begin
        // Initialize
        clk = 0;
        reset_active_low = 0;

        // Release reset after 3 clock cycles
        //remember reset signal is active low
        #3;
        reset_active_low = 1;
        #2;

        // Run for 10000 clock cycles
        repeat(10000) begin
            #1 clk = 1;
            #1 clk = 0;
        end

        // After 1000 cycles, check the value of x3 (gp)
        #1;
        //$display("\n=== Simulation Complete ===");
        //$display("x3 (gp) value: 0x%08h", dut.system_register_file.rf[3]);
        //$display("PC value: 0x%08h", dut.PC_tracking_register.result);
        //$display("Instruction: 0x%08h", dut.instruction);
        //$finish;
    end

    // Optional: dump waveforms for debugging
    initial begin
        $dumpfile("/workspaces/nano-rv32i/sim/auto-simulation.fst");
        $dumpvars(0, datapath_tb);
    end 
endmodule
