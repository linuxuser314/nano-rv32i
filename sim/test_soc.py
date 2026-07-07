import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.runner import get_runner

@cocotb.test()
async def run_riscv_test(dut):
    """Monitors your CPU's LED output to see if it passes or fails."""
    # 1. Start a 27MHz clock
    cocotb.start_soon(Clock(dut.clk_27MHz, 37, units="ns").start())

    # 2. Assert Reset for 5 clock cycles
    dut.reset_button.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk_27MHz)
    dut.reset_button.value = 0

    # 3. Watch the led_strip6 output
    last_led = 0
    for cycle in range(20000): # 20,000 cycle timeout safety net
        await RisingEdge(dut.clk_27MHz)
        
        try:
            current_led = int(dut.led_strip6.value)
        except ValueError:
            current_led = 0

        if current_led != last_led and current_led != 0:
            if current_led == 1:
                dut._log.info(f"🎉 SUCCESS: RISC-V TEST PASSED!")
                return
            else:
                dut._log.error(f"💥 ERROR: RISC-V TEST FAILED! Code: {current_led}")
                assert False
            last_led = current_led

    assert False, "Simulation Timeout! CPU hung."

if __name__ == "__main__":
    nano_root = os.environ.get("NANO_ROOT", os.getcwd())
    
    # Read your filelist.f automatically
    sources = []
    with open(os.path.join(nano_root, "filelist.f")) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("+") and not line.startswith("#"):
                sources.append(os.path.join(nano_root, line))
                
    # Run Verilator through Cocotb
    runner = get_runner("verilator")
    runner.build(
        verilog_sources=sources,
        hdl_toplevel="soc_top",
        always=True,
        build_dir=os.path.join(nano_root, "build/sim"),
        build_args=["-O3", "--x-assign", "fast", "--x-initial", "fast"],
        waves=True
    )
    runner.test(hdl_toplevel="soc_top", test_module="test_soc", test_dir=os.path.join(nano_root, "sim"), waves=True)