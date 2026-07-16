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

    VerilatedVpi::callValueCbs();

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
    
    // Track the tohost state to detect changes
    uint32_t prev_tohost = 0;
    int exit_code = 0;

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

        VerilatedVpi::callValueCbs(); 

        if (!top->reset_button) {
            // 1. Check for Hardware Faults
            if (sample_vpi_handle(h_load_fault) ||
                sample_vpi_handle(h_store_fault) ||
                sample_vpi_handle(h_load_misaligned) ||
                sample_vpi_handle(h_store_misaligned) ||
                sample_vpi_handle(h_fetch_fault) ||
                sample_vpi_handle(h_fetch_misaligned) ||
                sample_vpi_handle(h_invalid_inst)) {
                
                std::cerr << "\n[TB] ❌ FATAL: Core hardware fault condition tripped. Aborting." << std::endl;
                exit_code = 1;
                break;
            }

            // 2. Monitor tohost for riscv-tests output on the rising clock edge
            if (top->clk_27MHz && top->tohost != prev_tohost) {
                prev_tohost = top->tohost;
                
                if (top->tohost == 1) {
                    std::cout << "\n[TB] ✅ riscv-test PASSED (tohost = 1)" << std::endl;
                    exit_code = 0;
                    break;
                } 
                else if (top->tohost > 1 && (top->tohost & 1)) {
                    // riscv-tests failure signature: (test_num << 1) | 1
                    uint32_t test_num = top->tohost >> 1;
                    std::cerr << "\n[TB] ❌ riscv-test FAILED at test case: " << test_num 
                              << " (tohost = " << top->tohost << ")" << std::endl;
                    exit_code = 1;
                    break;
                }
            }
        }

        sim_time++;
    }

    if (sim_time >= max_sim_ticks) {
        std::cerr << "\n[TB] ⚠️ TIMEOUT: Simulation reached maximum ticks." << std::endl;
        exit_code = 1;
    }

    tfp->close();
    delete top;
    delete tfp;
    delete contextp;
    
    return exit_code;
}