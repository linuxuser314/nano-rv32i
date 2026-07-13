#include <iostream>
#include <verilated.h>
#include "Vsoc_top.h"
#include <verilated_fst_c.h>

uint64_t sim_time = 0;

double sc_time_stamp() {
    return sim_time;
}

int main(int argc, char** argv) {
    VerilatedContext* contextp = new VerilatedContext();
    contextp->commandArgs(argc, argv);

    Vsoc_top* top = new Vsoc_top(contextp);

    contextp->traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC();
    
    top->trace(tfp, 99); 
    // Updated path to reflect the build/verilator directory structure
    tfp->open("build/verilator/simulation.fst");

    top->clk_27MHz = 0;
    top->reset_button = 1; 

    uint64_t max_sim_ticks = 100000;

    while (!contextp->gotFinish() && sim_time < max_sim_ticks) {
        if (sim_time == 40) {
            top->reset_button = 0; 
        }

        if ((sim_time % 10) == 0) {
            top->clk_27MHz = !top->clk_27MHz;
        }

        top->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    tfp->close();
    
    delete top;
    delete tfp;
    delete contextp;

    return 0;
}