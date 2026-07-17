# nano-rv32i
This is a basic starter RV32I core. It is my first large hardware design project.

| Category | Component / Tool |
| :--- | :--- |
| **Target Hardware** | Sipeed Tang Nano 20K (Gowin GW2AR-LV18) |
| **HDL Language** | SystemVerilog |
| **Simulation** | Verilator |
| **Waveform Viewer** | Surfer |
| **Synthesis** | Yosys |
| **Place & Route** | NextPNR-Gowin |
| **Bitstream Tool** | Project Apicula |

## Design
 - **Target:** This core is targeted for the **Sipeed Tang Nano 20K**
 - **Toolchain:** I use **SystemVerilog**, **Verilator**, **Yosys**, and **NextPNR/Gowin** (**Project Apicula**).
 - **Architecture:** Uses the **RV32I Base Unprivileged Architecture**
 - **Microarchitecture:** Uses a **primarily Single-Cycle** architecture except for `load` instructions (see below).
 - **Memory:** Uses synchronous **Dual-Ported BRAM** for a seamless **Von Neumann** experience while maintaining Harvard simplicity in the hardware.
 - **Fetching:** Calculates the next PC *combinationally* before feeding it into the synchronous BRAM. This eliminates the need for a dedicated fetch cycle while working with FPGA primitives.
 - **Loads & Stores:** Because memory is synchronous, loads and stores present a challenge. Stores calculate the address and present the data on the memory port. It is committed on the rising edge of the clock. Loads calculate the address and present it to the memory address port. On the next cycle the result is read from the data port, it is shifted/masked (if necessary), and is written back to the register file. The load delay is managed by a FSM in the decoder (the decoder is combinational with an external 1-bit register for a load flag).
 - **Tested:** All operations have passed the `riscv-tests` suite except for ma_data, ld_st, and st_ld (all untested). However, due to continued development, the core has regressed. I intend to get it passing all tests again (via an automated script) shortly.

## Limitations
  - **Read-After-Write (RAW) Memory Hazards:** Currently the design uses read-before-write BRAM, which means that a store to a specific address immediately followed by a load from that address will read the **old** memory value. Since this is a rare case and I will have to modify it during pipelining anyway I will leave this for now.
  - **Misaligned Memory Accesses:** Currently, the core does not support misaligned memory accesses (`addr % 4 != 0` for words, `addr % 2 != 0` for halfwords). Since I am implementing an **Unprivileged Architecture**, I cannot currently add a **Trap Handler** to handle misaligned accesses.

---
## Current Progress
I am currently working on adding:
 - Adding an automated riscv-tests script
 - Fixing any failed tests
 - Automating tests via GitHub Actions

## Lessons Learned & Challenges Overcome
Throughout this process, I have spent many hours debugging weird quirks and trying to get my toolchain to work.
- **Learning SystemVerilog:** This is my first real SystemVerilog project, so I was getting familiar with the syntax of the language and it's various oddities.
- **Icarus Verilog Limitations:** I had to modify various parts of my code so I could sucessfully use Icarus Verilog (`iverilog`) for simulation, since it does not support full modern SystemVerilog.
- **RISC-V GNU Toolchain:** Overcoming the complications of preprocessors, linker scripts, macros, and more.
- **RISC-V Tests:** Getting valid Verilog .hex files from assembly using the GNU toolchain and overcoming complex macro headers.
- `$readmemh` **and OSS CAD:** OSS Cad (specifically **Project Apicula** (`gowin_pack`) is apparently finicky when it comes to loading data into dual-ported Block RAM at startup. This caused hours of frustration and the classic "it works in simulation, but not in synthesis" error not because my code was incorrect, but because my toolchain was silently deleting my code and causing my processor to go into an error state when it fetched the first instruction from zeroed-out BRAM.

## Development Methodology

I learned about RISC-V using Sarah and David Harris's *Digital Design and Computer Architecture, RISC-V Edition* (2022). I used their SystemVerilog references, schematics, and appendices to design this core, expanding where they missed instructions and optimizing for synchronous memory.

Throughout this process I have used Google Gemini AI and GitHub Copilot for brainstorming, debugging, rubber-ducking, improvement suggestion, testbenches, and toolchain management (build scripts, linker scripts, quick assembly tests). 95% of the RTL is my own, but AI proved to be an invaluable tutor.
