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
 - **Microarchitecture:** Uses a **primarily Single-Cycle** architecture except for `load` instructions (see below).
 - **Memory:** Uses synchronous **Dual-Ported BRAM** for a seamless **Von Neumann** experience while maintaining Harvard simplicity in the hardware.
 - **Fetching:** Calculates the next PC *combinationally* before feeding it into the synchronous BRAM. This eliminates the need for a dedicated fetch cycle while working with FPGA primitives.
 - **Loads & Stores:** Because memory is synchronous, loads and stores present a challenge. Stores calculate the address and present the data on the memory port. It is committed on the rising edge of the clock. Loads calculate the address and present it to the memory address port. On the next cycle the result is read from the data port, it is shifted/masked (if necessary), and is written back to the register file. The load delay is managed by a FSM in the decoder (the decoder is combinational with an external 1-bit register for a load flag).
 - **Tested:** All operations pass the official `riscv-tests` suite (except for ma_data, see below).

## Limitations
  - **Read-After-Write (RAW) Memory Hazards:** Currently the design uses read-before-write BRAM, which means that a store to a specific address immediately followed by a load from that address will read the **old** memory value. Since this is a rare case and I will have to modify it during pipelining anyway I will leave this for now.
  - **Misaligned Memory Accesses:** Currently, the core does not support misaligned memory accesses (`addr % 4 != 0` for words, `addr % 2 != 0` for halfwords). Since I am implementing an **Unprivileged Architecture**, I cannot currently add a **Trap Handler** to handle misaligned accesses.

---

## TODO:
### Short Term
- [x] Compile, simulate, and testbench all small components.
- [x] Compile, simulate, and testbench all major components.
- [x] Finish anything I forgot on the datapath module.
- [x] Build the decoder module (one giant casez statement).
- [x] Make memory use Gowin BRAM natively.
- [x] Add code to import memory.
- [x] Run riscv-tests to make sure it's all working properly.
- [x] Clean up testfiles in my repository.
- [x] Update devcontainer.json for full automatic setup.
- [x] Synthesize it to my FPGA.
- [ ] Clean up and refactor code:
  - [x] Refactor my code to have an internal core module and a top-level SoC module that links to memory, MMIO, etc.
  - [ ] Add a boot ROM and payload data for proper flashing while bypassing Project Apicula's limitations for data initialization in dual-ported BRAM
  - [ ] Go through each module and add proper comments, remove old commented-out code, etc.
  - [x] Restructure my `rtl` directory for my rapidly growing set of modules
  - [ ] Update build scripts to reflect updated directory structure
  - [ ] Move memory components from datapath and rename datapath to rv32i_core to integrate it into the SoC design.
  - [ ] Test SoC design
- [ ] Add MMIO for program output and for debugging.
- [ ] Write a program in assembly that mimics the functionality of my `Baremetal-Blinker` repository.
- [ ] Add a functioning bootloader that loads a binary file from SPI flash and/or UART so I can flash my core without re-synthesizing it.
- [ ] Add makefile for easier startup.
- [ ] Create automatic riscv-tests testing script and deploy with GitHub Actions.
- [ ] Use riscv-torture and incorporate that into my testing routine.
- [ ] Use symbiyosys for formal verification of my core and add to automation setup.
### Long Term  
- [ ] Turn it into a pipelined processor  
- [ ] Add Zicsr extension
- [ ] Add B extension  
- [ ] Add C extension  
- [ ] Add M extension  
- [ ] Do a deep-dive performance analysis to tune it for improved performance  
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

## Lessons Learned & Challenges Overcome
Throughout this process, I have spent many hours debugging weird quirks and trying to get my toolchain to work.
- **Learning SystemVerilog:** This is my first real SystemVerilog project, so I was getting familiar with the syntax of the language and it's various oddities.
- **Icarus Verilog Limitations:** I had to modify various parts of my code so I could sucessfully use Icarus Verilog (`iverilog`) for simulation, since it does not support full modern SystemVerilog.
- **RISC-V GNU Toolchain:** Overcoming the complications of preprocessors, linker scripts, macros, and more.
- **RISC-V Tests:** Getting valid Verilog .hex files from assembly using the GNU toolchain and overcoming complex macro headers.
- `$readmemh` **and OSS CAD:** OSS Cad (specifically **Project Apicula** (`gowin_pack`) is apparently finicky when it comes to loading data into dual-ported Block RAM at startup. This caused hours of frustration and the classic "it works in simulation, but not in synthesis" error not because my code was incorrect, but because my toolchain was silently deleting my code and causing my processor to go into an error state when it fetched the first instruction from zeroed-out BRAM.

## Development Methodology

I learned about RISC-V using Sarah and David Harris's *Digital Design and Computer Architecture, RISC-V Edition* (2022). I used their SystemVerilog references, schematics, and appendices to design this core, expanding where they missed instructions and optimizing for synchronous memory.

Throughout this process I have used Google Gemini AI and GitHub Copilot for brainstorming, debugging, rubber-ducking, improvement suggestion, testbenches, and toolchain management (build scripts, linker scripts, quick assembly tests). 95% of the RTL is my own, but I could not have done it without AI as a tutor.