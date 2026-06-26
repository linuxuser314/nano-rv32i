`default_nettype none

module bus_interconnect();
    //Everything goes here...
     //Internal signals for memory selection
    logic        boot_rom_read_enable;
    logic [31:0] boot_rom_addr, boot_rom_result;


    logic [1:0]  fetch_select;
    logic [1:0]  data_select;
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
        fetch_select = 0;

        boot_rom_read_enable = 1'b0;//Could I just put 0 in each of these locations?
        boot_rom_fetch_addr = 32'b0;
        case(fetch_addr[31:30])
            0: begin
                //0x0000_0000 to 0x0000_08FF: ROM (x)
                if(fetch_addr >= 32'h0000_0000 && fetch_addr <= 32'h0000_08FF) begin
                    boot_rom_read_enable = 1;
                    boot_rom_addr = fetch_addr;
                    fetch_select = 2'b0;
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

endmodule
