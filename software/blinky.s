# blinky.s

.text
.globl _start

_start:
    li x10, 0              # x10 will be our LED state counter
    li x12, 0x40000000     # x12 holds the tohost memory address

main_loop:
    addi x10, x10, 1       # Increment the LED state by 1
    
    # Write the lowest bits of x10 to the LEDs. 
    # (Since LEDs are active-low, you could do 'not x13, x10' first if you want 
    # it to count up normally, but let's just push raw numbers first!)
    sw x10, 0(x12)         
    
    # --- DELAY LOOP ---
    # The CPU runs at 58,000,000 ticks per second.
    # This loop takes about 3 instructions per iteration.
    # 5,000,000 iterations * 3 = 15,000,000 cycles (roughly 1/4th of a second).
    li x11, 5000000        
delay_loop:
    addi x11, x11, -1      # Subtract 1 from x11
    bne x11, x0, delay_loop # If x11 is not 0, jump back up
    # ------------------

    j main_loop            # Jump back to the beginning
    