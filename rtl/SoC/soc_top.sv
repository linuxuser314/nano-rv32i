//This is the top SoC module.


/*
Memory Map (18Kbit aligned for BRAM):
0x0000_0000 to 0x0000_08FF: ROM (x)
0x4000_0000 to 0x4000_08FF: Payload (r)
0x8000_0000 to 0x8000_08FF: MMIO (rw, volatile tag in C/C++ mandatory)
0xC000_0000 to 0xC000_08FF: RAM (rwx)
*/

`default_nettype none

module soc_top(input  logic      clk_27MHz, reset_button,
               output logic[5:0] led_strip6
               );
    logic[31:0] fetch_addr, fetch_data;
    logic       fetch_enable;
    logic       FETCH_FAULT;
    logic[31:0] data_addr, load_data, store_data;
    logic       data_read_enable, data_write_enable;
    logic[3:0]  data_write_enable_control;
    logic DATA_FAULT;

    rv32i_core core0(
        //Instruction fetching
        .fetch_addr(fetch_addr), .fetch_data(fetch_data),
        .fetch_enable(fetch_enable),
        .FETCH_FAULT(FETCH_FAULT),

        //Data reading/writing
        .data_addr(data_addr), .load_data(load_data), .store_data(store_data),
        .data_read_enable(data_read_enable), .data_write_enable(data_write_enable),
        .data_write_enable_control(data_write_enable_control),
        .DATA_FAULT(DATA_FAULT),

        //Simple passthrough (for now)
        .clk(clk_27MHz), .reset(reset_button)
    );

    always_comb begin

        //Data calculation
        DATA_FAULT = 0;
        case(data_addr[31:30])
            0: begin
                //0x0000_0000 to 0x0000_08FF: ROM (x)
                DATA_FAULT = 1;//Region 0 does not have rw privleges.
            end
            1: begin
                //0x4000_0000 to 0x4000_08FF: Payload ROM(r)
                if(data_write_enable) begin
                    DATA_FAULT = 1;//Region 1 does not have w privleges.
                end
                else if(data_read_enable) begin
                    if(data_addr >= 32'h4000_0000 && data_addr <= 32'h4000_08FF) begin
                        //Paylod ROM read access goes here
                    end
                    else DATA_FAULT = 1;
                end
            end
            2: begin
                //0x8000_0000 to 0x8000_08FF: MMIO (rw, volatile attribute in C/C++ mandatory)
                if(data_addr >= 32'h8000_0000 && data_addr <=32'h8000_08FF) begin
                    //MMIO reading/writing code goes here
                end
                else DATA_FAULT = 1;
            end
            3: begin
                //0xC000_0000 to 0xC000_08FF: RAM (rwx)
                if(data_addr >= 32'hC000_0000 && data_addr <= 32'hC000_08FF) begin
                    //RAM reading/writing code goes here
                end
                else DATA_FAULT = 1;
            end
            default: DATA_FAULT = 1;
        endcase

        //Fetch component
        FETCH_FAULT = 0;
        case(fetch_addr[31:30])
            0: begin
                //0x0000_0000 to 0x0000_08FF: ROM (x)
                if(fetch_addr >= 32'h0000_0000 && fetch_addr <= 32'h0000_08FF) begin
                    //Fetching logic goes here
                end
                else FETCH_FAULT = 1;
            end
            1: begin
                //0x4000_0000 to 0x4000_08FF: Payload ROM(r)
                FETCH_FAULT = 1;//Payload ROM only has r privleges.
            end
            2: begin
                //0x8000_0000 to 0x8000_08FF: MMIO (rw, volatile attribute in C/C++ mandatory)
                FETCH_FAULT = 1;//MMIO only has rw privleges
            end
            3: begin
                //0xC000_0000 to 0xC000_08FF: RAM (rwx)
                if(fetch_addr >= 32'hC000_0000 && fetch_addr <= 32'hC000_08FF) begin
                    //Fetching code goes here
                end
                else FETCH_FAULT = 1;
            end
            default: FETCH_FAULT = 1;
        endcase
    end

    ram2P system_ram(

    );
    rom1P boot_rom #(
        FILE_PATH = "/workspaces/nano-rv32i/software/boot_rom.hex",
        SIZE = 2304
    ) (
        .clk(), .read_enable(),
        .address(), .result(),

    );
    rom1P payload_rom(
        
    );
    mmio system_MMIO(

    );
endmodule
