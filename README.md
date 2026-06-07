# nano-rv32i
This is where I am putting first RISC-V RV32I single-cycle processor (in development)
It is targeted for the Sipeed Tang Nano 20K.

It is single-cycle except for loads (which are two-cycle).

THIS PROCESSOR IS NOT YET TESTED! I HAVE CODED IT BUT I HAVE NOT RUN TESTBENCHES AND IT CONTAINS KNOWN AND UNKNOWN ERRORS.
I believe that I and R-type math instructions (opcodes 19 and 51), branches (op 99), and lui (op 55) are all working. I encountered some issues with jal and jalr and auipc are untested. Loads and stores are not fully implemented yet and will throw an error.

I hope to have it up and running by the end of the week (failed: I now hope to have it by the end of next week (the 13th)). I will complete the readme then.

Thank you for your patience.

# TODO:
Short Term:
    Compile, simulate, and testbench all small components
    Compile, simulate, and testbench all major components
    Finish anything I forgot on the datapath module
    Build the decoder module (one giant casez statement)
    Make memory use Gowin BRAM natively
    Add code to import memory
    Add error handling module that flashes an LED
    Add MMIO for program output and for debugging
    Run riscv-tests to make sure it's all working properly
    Clean up and refactor code for readability and maintainability
    Do a deep-dive performance analysis to tune it for improved performance
Long Term:
    Turn it into a pipelined processor
    Add B extension
    Add C extension
    Add M extension
    Add a bootloader
    Add an exception handler that uses UART for debugging
    Make the exception handler handle misaligned memory loads/stores or implement it in hardware
    Create a full MMIO 
    Link to DRAM
    Create a HAL
    Create an RTOS
Ultra long-term:
    Add asymetric superscalarism
    Add scoreboarded light OoO
