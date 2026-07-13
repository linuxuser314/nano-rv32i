#include <iostream>
#include <verilated.h>
#include "Vsoc_top.h"
#include <verilated_fst_c.h>
#include <verilated_vpi.h> 

uint64_t sim_time = 0;

double sc_time_stamp() {
    return sim_time;
}

// Optimized helper function that samples an already resolved handle
bool sample_vpi_handle(vpiHandle handle) {
    if (!handle) return false;
    s_vpi_value v;
    v.format = vpiScalarVal;
    vpi_get_value(handle, &v);
    return (v.value.scalar == vpi1);
}

int main(int argc, char** argv) {
    VerilatedContext* contextp = new VerilatedContext();
    contextp->commandArgs(argc, argv);

    Vsoc_top* top = new Vsoc_top(contextp);

    contextp->traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC();
    
    top->trace(tfp, 99); 
    tfp->open("/workspaces/nano-rv32i/logs/verilator/simulation.fst");

    // Initialize VPI context structures
    VerilatedVpi::callValueCbs();

    // =====================================================================
    // VPI HANDLE CACHING (Look up once at startup)
    // =====================================================================
    std::cout << "[TB] Resolving internal fault monitoring VPI handles..." << std::endl;
    vpiHandle h_load_fault        = vpi_handle_by_name((PLI_BYTE8*)"TOP.soc_top.core0.LOAD_FAULT", NULL);
    vpiHandle h_store_fault       = vpi_handle_by_name((PLI_BYTE8*)"TOP.soc_top.core0.STORE_FAULT", NULL);
    vpiHandle h_load_misaligned   = vpi_handle_by_name((PLI_BYTE8*)"TOP.soc_top.core0.LOAD_MISALIGNED", NULL);
    vpiHandle h_store_misaligned  = vpi_handle_by_name((PLI_BYTE8*)"TOP.soc_top.core0.STORE_MISALIGNED", NULL);
    vpiHandle h_fetch_fault       = vpi_handle_by_name((PLI_BYTE8*)"TOP.soc_top.core0.FETCH_FAULT", NULL);
    vpiHandle h_fetch_misaligned  = vpi_handle_by_name((PLI_BYTE8*)"TOP.soc_top.core0.FETCH_MISALIGNED", NULL);
    vpiHandle h_invalid_inst      = vpi_handle_by_name((PLI_BYTE8*)"TOP.soc_top.core0.INVALID_INSTRUCTION", NULL);

    top->clk_27MHz = 0;
    top->reset_button = 1; 

    uint64_t max_sim_ticks = 100000;

    std::cout << "[TB] Beginning optimized simulation loop..." << std::endl;

    while (!contextp->gotFinish() && sim_time < max_sim_ticks) {
        if (sim_time == 40) {
            top->reset_button = 0; 
        }

        if ((sim_time % 10) == 0) {
            top->clk_27MHz = !top->clk_27MHz;
        }

        top->eval();
        tfp->dump(sim_time);

        // Service the VPI internal state engine
        VerilatedVpi::callValueCbs(); 

        // Fast pointer evaluations using cached handles
        if (!top->reset_button) {
            if (sample_vpi_handle(h_load_fault) ||
                sample_vpi_handle(h_store_fault) ||
                sample_vpi_handle(h_load_misaligned) ||
                sample_vpi_handle(h_store_misaligned) ||
                sample_vpi_handle(h_fetch_fault) ||
                sample_vpi_handle(h_fetch_misaligned) ||
                sample_vpi_handle(h_invalid_inst)) {
                
                std::cerr << "\n[TB] ❌ FATAL: Core hardware fault condition tripped. Aborting simulation loop." << std::endl;
                
                tfp->close();
                delete top;
                delete tfp;
                delete contextp;
                return 1;
            }
        }

        sim_time++;
    }

    tfp->close();
    delete top;
    delete tfp;
    delete contextp;
    return 0;
}