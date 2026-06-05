`default_nettype none
`timescale 1ns/1ps

module datapath_tb;
    logic clk, reset;

    // Instantiate the datapath
    datapath uut(
        .clk(clk),
        .reset(reset)
    );

    initial begin
        // Initialize
        clk = 0;
        reset = 1;

        // Release reset after 3 clock cycles
        #3;
        reset = 0;

        // Run for 1000 clock cycles
        repeat(10000) begin
            #1 clk = 1;
            #1 clk = 0;
        end

        // After 1000 cycles, check the value of x3 (gp)
        #1;
        $display("\n=== Simulation Complete ===");
        $display("x3 (gp) value: 0x%08h", uut.system_register_file.rf[3]);
        $display("PC value: 0x%08h", uut.PC_tracking_register.result);
        $display("Instruction: 0x%08h", uut.instruction);
        $finish;
    end

    // Optional: dump waveforms for debugging
    initial begin
        $dumpfile("datapath_sim.vcd");
        $dumpvars(0, datapath_tb);
    end
endmodule
