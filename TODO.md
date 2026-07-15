
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
  - [x] Add a boot ROM and payload data for proper flashing while bypassing Project Apicula's limitations for data initialization in dual-ported BRAM
  - [ ] Go through each module and add proper comments, remove old commented-out code, etc.
  - [x] Restructure my `rtl` directory for my rapidly growing set of modules
  - [x] Move memory components from datapath and rename datapath to rv32i_core to integrate it into the SoC design.
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