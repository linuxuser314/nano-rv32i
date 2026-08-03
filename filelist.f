// Include Directories (Macros and Headers)
+incdir+rtl/interfaces
+incdir+rtl/rv32i_core
+incdir+rtl/utils
+incdir+rtl/peripherals
+incdir+rtl/SoC

// 1. Interfaces
rtl/interfaces/ram_bus_if.sv

// 2. Utilities
rtl/utils/adder.sv
rtl/utils/byte_shift_left.sv
rtl/utils/byte_shift_right.sv
rtl/utils/mux2.sv
rtl/utils/mux8.sv
rtl/utils/dff_register.sv
rtl/utils/shifter.sv
rtl/utils/ram_single_port.sv
rtl/utils/ram_dual_port.sv

// 3. Core Modules
rtl/rv32i_core/address_check.sv
rtl/rv32i_core/ALU_comparator.sv
rtl/rv32i_core/decoder.sv
rtl/rv32i_core/imm_dec_ext.sv
rtl/rv32i_core/instruction_rom.sv
rtl/rv32i_core/mask.sv
rtl/rv32i_core/load.sv
rtl/rv32i_core/store.sv
rtl/rv32i_core/load_store_unit.sv
rtl/rv32i_core/PC_subsystem.sv
rtl/rv32i_core/register_file.sv
rtl/rv32i_core/fetch_unit.sv
rtl/rv32i_core/rv32i_core.sv

// 4. Peripherals & SoC
rtl/peripherals/mmio.sv
rtl/peripherals/uart_shift_register.sv
rtl/peripherals/baud_generator.sv
rtl/peripherals/uart_tx.sv
rtl/peripherals/uart_rx.sv

rtl/SoC/uart_dma_flasher.sv
rtl/SoC/bus_interconnect.sv
rtl/SoC/soc_top.sv