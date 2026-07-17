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
    
    uint32_t prev_tohost = 0;
    uint8_t prev_clk = 0;
    int exit_code = 0;
    int fault_countdown = -1; // -1 means no fault detected yet

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
            // Evaluate strictly on the positive clock edge
            if (top->clk_27MHz && !prev_clk) {
                
                // 1. Check for Hardware Faults (if not already counting down)
                if (fault_countdown < 0) {
                    bool fault_detected = false;
                    
                    if (sample_vpi_handle(h_load_fault))       { std::cerr << "\n[TB] ⚡ Detected LOAD_FAULT"; fault_detected = true; }
                    if (sample_vpi_handle(h_store_fault))      { std::cerr << "\n[TB] ⚡ Detected STORE_FAULT"; fault_detected = true; }
                    if (sample_vpi_handle(h_load_misaligned))  { std::cerr << "\n[TB] ⚡ Detected LOAD_MISALIGNED"; fault_detected = true; }
                    if (sample_vpi_handle(h_store_misaligned)) { std::cerr << "\n[TB] ⚡ Detected STORE_MISALIGNED"; fault_detected = true; }
                    if (sample_vpi_handle(h_fetch_fault))      { std::cerr << "\n[TB] ⚡ Detected FETCH_FAULT"; fault_detected = true; }
                    if (sample_vpi_handle(h_fetch_misaligned)) { std::cerr << "\n[TB] ⚡ Detected FETCH_MISALIGNED"; fault_detected = true; }
                    if (sample_vpi_handle(h_invalid_inst))     { std::cerr << "\n[TB] ⚡ Detected INVALID_INSTRUCTION"; fault_detected = true; }

                    if (fault_detected) {
                        std::cerr << " -> Waiting 3 cycles before exit to capture waveform..." << std::endl;
                        fault_countdown = 3; 
                    }
                }

                // 2. Handle Countdown
                if (fault_countdown >= 0) {
                    if (fault_countdown == 0) {
                        std::cerr << "[TB] ❌ FATAL: Fault countdown reached. Aborting." << std::endl;
                        exit_code = 1;
                        break;
                    }
                    fault_countdown--;
                }

                // 3. Monitor tohost (only if not faulting)
                if (fault_countdown < 0 && top->tohost != prev_tohost) {
                    prev_tohost = top->tohost;
                    if (top->tohost == 1) {
                        std::cout << "\n[TB] ✅ riscv-test PASSED (tohost = 1)" << std::endl;
                        exit_code = 0;
                        break;
                    } 
                    else if (top->tohost > 1 && (top->tohost & 1)) {
                        uint32_t test_num = top->tohost >> 1;
                        std::cerr << "\n[TB] ❌ riscv-test FAILED at test case: " << test_num 
                                  << " (tohost = " << top->tohost << ")" << std::endl;
                        exit_code = 1;
                        break;
                    }
                }
            }
        }

        prev_clk = top->clk_27MHz;
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