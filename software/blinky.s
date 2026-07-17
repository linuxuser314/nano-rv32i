.section .text
.globl _start

_start:
    # 1. Initialize our base registers
    li t0, 0x80000000    # t0 = MMIO Base Address (0x8000_0000)
    li t1, 0             # t1 = LED Binary Counter (Starts at 0)

main_loop:
    # 2. Write the current binary count to the LEDs
    # (Hardware will naturally ignore anything above bit 5)
    sw t1, 0(t0)         

    # ====================================================================
    # 3. ADJUSTABLE DELAY
    # Change the number below! 
    # Use '5' for Simulation. Use '1000000' (or more) for the FPGA.
    # ====================================================================
    li t2, 2            
    
    # 4. Reset the current delay counter
    li t3, 0             

delay_loop:
    # If our delay counter (t3) is greater than or equal to our target (t2), exit loop
    bge t3, t2, delay_done  
    addi t3, t3, 1       # Increment the delay counter
    j delay_loop         # Jump back to the start of the delay loop

delay_done:
    # 5. Increment the actual LED binary count and repeat forever
    addi t1, t1, 1       
    j main_loop
