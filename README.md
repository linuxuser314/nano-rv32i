# nano-rv32i
This is a basic starter RV32I core. It is my first large hardware design project.

| Category | Component / Tool |
| :--- | :--- |
| **Target Hardware** | Sipeed Tang Nano 20K (Gowin GW2AR-LV18) |
| **HDL Language** | SystemVerilog |
| **Simulation** | Icarus Verilog (`iverilog`) + VVP |
| **Waveform Viewer** | Surfer |
| **Synthesis** | Yosys |
| **Place & Route** | NextPNR-Gowin |
| **Bitstream Tool** | Project Apicula |

## Design
 - **Target:** This core is targeted for the **Sipeed Tang Nano 20K**
 - **Toolchain:** I use **SystemVerilog**, **Icarus Verilog**, **Yosys**, and **NextPNR/Gowin** (**Project Apicula**).
 - **Architecture:** Uses the **RV32I Base Unprivileged Architecture**
 - **Microarchitecture:** Uses a **Single-Cycle** architecture except for `load` instructions (see below).
 - **Memory:** Uses synchronous **Dual-Ported BRAM** for a seamless **Von Neumann** experience while maintaining Harvard simplicity in the hardware.
 - **Fetching:** Calculates the next PC *combinationally* before feeding it into the synchronous BRAM. This eliminates the need for a dedicated fetch cycle while working with FPGA primatives.
 - **Loads & Stores:** Because memory is synchronous, loads and stores present a challenge. Stores calculate the address and present the data on the memory port. It is committed on the rising edge of the clock. Loads calculate the address and present it to the memory address port. On the next cycle the result is read from the data port, it is shifted/masked (if necessary), and is written back to the register file. The load delay is managed by a FSM in the decoder (the decoder is combinational with an external 1-bit register for a load flag).
 - **Tested:** All operations pass the official `riscv-tests` suite (except for ma_data, see below).

## Limitations
  - **Read-After-Write (RAW) Memory Hazards:** Currently the design uses read-before-write BRAM, which means that a store to a specific address immediately followed by a load from that address will read the **old** memory value. Since this is a rare case and I will have to modify it during pipelining anyway I will leave this for now.
  - **Misaligned Memory Accesses:** Currently, the core does not support misaligned memory accesses (`addr % 4 != 0` for words, `addr % 2 != 0` for halfwords). Since I am implementing an **Unprivileged Architecture**, I cannot currently add a **Trap Handler** to handle misaligned accesses.

---

## TODO:
### Short Term
- [x] Compile, simulate, and testbench all small components  
- [x] Compile, simulate, and testbench all major components  
- [x] Finish anything I forgot on the datapath module  
- [x] Build the decoder module (one giant casez statement)  
- [x] Make memory use Gowin BRAM natively  
- [x] Add code to import memory  
- [x] Run riscv-tests to make sure it's all working properly  
- [x] Clean up testfiles in my repository
- [x] Update devcontainer.json for full automatic setup
- [ ] Add makefile for easier startup (currently requires complex manual scripting, let me know if you have questions. Sorry).
- [ ] Create automatic riscv-tests testing script and deploy with GitHub Actions.
- [ ] Synthesize it to my FPGA.
- [ ] Add MMIO for program output and for debugging  .
- [ ] Clean up and refactor code for readability and maintainability.
- [ ] Write a program in assembly that mimics the functionality of my `Baremetal-Blinker` repository.
### Long Term  
- [ ] Turn it into a pipelined processor  
- [ ] Add Zicsr extension
- [ ] Add B extension  
- [ ] Add C extension  
- [ ] Add M extension  
- [ ] Do a deep-dive performance analysis to tune it for improved performance  
- [ ] Add a bootloader  
- [ ] Add an exception handler that uses UART for debugging  
- [ ] Make the exception handler handle misaligned memory loads/stores or implement it in hardware  
- [ ] Create a full MMIO  
### Ultra long-term
- [ ] Build a simple operating system
- [ ] Add micro-POSIX features using Newlib and syscalls
- [ ] Connect a system bus and DRAM controller.
- [ ] Integrate MMIO and caches into memory bus
- [ ] Add multicore processing
- [ ] Add a lightweight fully customized  MMU and integrate it into my RTOS
- [ ] Create a command-line operating system using POSIX-compliant C utilities
- [ ] Use TCC for self-hosting compilation
- [ ] Add video/audio drivers and IO
- [ ] Add a GUI running in userspace for my OS
- [ ] Add GUI apps
- [ ] Emulate or manage directly in hardware for another architecture to emulate a computer or game controller (for example an NES emulator or a parallel MIPS decoder for PS1)
- [ ] One major architectural feature such as deep pipelining, scoreboarded OoO, or superscalarism.


## Development Methodology

I learned about RISC-V using Sarah and David Harris's *Digital Design and Computer Architecture, RISC-V Edition* (2022). I used their SystemVerilog references, schematics, and appendices to design this core, expanding where they missed instructions and optimizing for synchronous memory.

Throughout this process I have used Google Gemini AI and GitHub Copilot for brainstorming, debugging, rubber-ducking, improvment suggestion, testbenches, and toolchain management (build scripts, linker scripts, quick assembly tests). 95% of the RTL is my own, but I could not have done it without AI as a tutor.