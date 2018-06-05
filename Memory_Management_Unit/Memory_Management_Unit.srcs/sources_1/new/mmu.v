`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2018 05:34:13
// Design Name: 
// Module Name: mmu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mmu(

        clk,
        reset,
        mmu_enable,
        virtual_address,
        transfer_length,
        burst_type,
        read,
        TTBR_read,
        enable_RW,
        instruction,//1 for instruction access and 0 for data access
        supervisor,
        fault_address_register,
        fault_status_register,
        physical_address,
        data_in,
        data_out
    );
    
    input clk;
    input reset;
    input mmu_enable;
    input[27:0] virtual_address;
    input[3:0] transfer_length;
    input[1:0] burst_type;
    input read;
    input TTBR_read;
    input enable_RW;
    input instruction;
    input supervisor;
    output reg[31:0] fault_address_register;
    output reg[3:0] fault_status_register;
    output reg[21:0] physical_address;
    input[31:0] data_in;
    output reg[31:0] data_out;
    
    
    //mmu registers
    reg[31:0] TTBR;
    reg[31:0] Domain_Access_Control_Register;
    
    
    //AXI Slave inputs
    
    reg[3:0] awid;
    reg[31:0] awaddr;
    reg[3:0] awlen;//maximum of 16 ttransfers
    reg[1:0] awsize;//max is 7 ,128 length, not sure
    reg[1:0] awburst;//burst type of either fixed,incremental or wrapping burst
    reg awvalid;
    wire awready;
    
    //write data channel
    
    reg[3:0] wid;
    reg[31:0] wdata;
    reg[3:0] wstrb;
    reg wlast;
    reg wvalid;
    wire wready;
    
    //write response channel
    
    wire[3:0] bid;
    wire[1:0] bresp;
    wire bvalid;
    reg bready;
    
    //read address channel
    reg[3:0] arid;
    reg[31:0] araddr;
    reg[3:0] arlen;
    reg[1:0] arsize;
    reg[1:0] arburst;
    reg arvalid;
    wire arready;
    
    //read data channel signals
    
    wire[3:0] rid;
    wire[31:0] rdata;
    wire[1:0] rresp;
    wire rlast;
    wire rvalid;
    reg rready; 
    
    
    //translation buffer inputs
    
    reg[27:0] TLB_virtual_address;
    reg[21:0] TLB_physical_address_input;
    reg[7:0] TLB_properties_input;
    reg TLB_read;
    reg TLB_enable_RW;
    wire[21:0] TLB_physical_address;
    wire[7:0] TLB_properties;
    wire TLB_hit;
    
    //cache signals
   reg[21:0] cache_address;
   reg cache_read;
   reg cache_enable_RW;
   reg[31:0] cache_data_in;
   wire[31:0] cache_data_out;
   wire cache_hit; 
    
    
    //reg for write transfer
    reg[3:0] no_of_wr_transfers;
    
    
    
    //mmu signals
    reg[4:0] mmu_state;
    reg[31:0] first_descriptor;
    reg[31:0] second_descriptor;
    reg[3:0] no_of_cache_transfers;
    parameter MMU_IDLE_STATE=5'd0;
    parameter MMU_CHECK_IN_TLB=5'd1;
    parameter WAIT_FOR_ARREADY=5'd2;
    parameter WAIT_FOR_FIRST_DESCRIPTOR=5'd3;
    parameter WAIT_FOR_ARREADY2=5'd4;
    parameter WAIT_FOR_SECOND_DESCRIPTOR=5'd5;
    parameter WRITE_BACK_IN_TLB=5'd6;
    parameter MMU_DISABLED_WAIT_FOR_ARREADY=5'd7;
    parameter MMU_DISABLED_WAIT_FOR_RVALID=5'd8;
    parameter MMU_DISABLED_WAIT_FOR_AWREADY=5'd9;
    parameter MMU_DISABLED_WAIT_FOR_WREADY=5'd10;
    parameter MMU_DISABLED_WAIT_FOR_BVALID=5'd11;
    parameter WAIT_FOR_CLK_CYCLE=5'd12;
    parameter CHECK_FOR_CACHE_HIT=5'd13;
    parameter CACHE_ADDRESS_ON_BUS=5'd14;
    parameter WAIT_FOR_CACHE_DATA=5'd15;
    parameter CACHE_FILL=5'd16;
    parameter WAIT_FOR_CLK_CYCLE_FOR_WRITE=5'd17;
    parameter CHECK_FOR_CACHE_HIT_WRITE=5'd18;
    parameter WAIT_FOR_AWADDRESS_TRANSFER=5'd19;
    parameter WAIT_FOR_WREADY_TO_TRANSFER=5'd20;
    parameter WAIT_FOR_WRESPONSE=5'd21;
    
    
    AXI_Slave_RAM DRAM_Slave(
        clk,reset,
        
        //write address channel
        awid,awaddr,awlen,awsize,awburst,awvalid,awready,
        
        //write data channel
        
        wid,wdata,wstrb,wlast,wvalid,wready,
        
        //write response channel
        
        bid,bresp,bvalid,bready,
        
        //read address channel
        arid,araddr,arlen,arsize,arburst,arvalid,arready,
        
        //read data channel signals
        
        rid,rdata,rresp,rlast,rvalid,rready
        );
    

    
    Translation_Buffer translationbuffer(
            clk,
            reset,
            TLB_virtual_address,
            TLB_physical_address_input,
            TLB_properties_input,
            TLB_read,
            TLB_enable_RW,
            TLB_physical_address,
            TLB_properties,
            TLB_hit
            );
    
    
    cache Cache(
            clk,
            cache_address,
            reset,
            cache_read,
            cache_enable_RW,
            cache_data_in,
            cache_data_out,
            cache_hit  
            );
    
    
    
    //process for TTBR
    always@(posedge clk or negedge reset)
    begin
        if(!reset)
        begin
            TTBR<=0;
        end
        else
        begin
            if(enable_RW)
            begin
                if(!TTBR_read)
                begin
                    TTBR<=virtual_address;//should be changed
                end
            end
        end
    end
    

    always@(posedge clk or negedge reset)
    begin
        if(!reset)
        begin
            mmu_state<=MMU_IDLE_STATE;
            
            physical_address<=0;
            TLB_virtual_address<=0;
            TLB_enable_RW<=0;
            TLB_read<=0;
            
            
            //driving all bus signals
            arid=0;
            araddr=0;
            arsize=0;
            arlen=0;
            arvalid<=0;
            arburst=0;
            
            awid=0;
            awaddr=0;
            awsize=0;
            awlen=0;
            awvalid<=0;
            awburst=0;
            
            
            rready<=0;
            
            wid<=0;
            wdata<=0;
            wlast<=0;
            wvalid<=0;
            wstrb=0;
            
            bready=0;
            
            
            fault_address_register=0;
            fault_status_register=0;
            
            no_of_cache_transfers=0;
            
            data_out=0;
            
            no_of_wr_transfers=0;
        end
        else
        begin
            case(mmu_state)
                MMU_IDLE_STATE:
                begin
                    if(mmu_enable)
                    begin
                        if(enable_RW)//either a read or a write operation
                        begin
                            TLB_virtual_address<=virtual_address;
                            TLB_enable_RW<=1;
                            TLB_read=1;
                            mmu_state<=MMU_CHECK_IN_TLB;
                        end
                        else
                        begin
                            mmu_state<=MMU_IDLE_STATE;
                              
                        end
                    end
                    else
                    begin
                        if(enable_RW)
                        begin
                            if(read)//read
                            begin
                                araddr={4'b0000,virtual_address};
                                arsize=2'b10;
                                arlen=transfer_length;
                                arburst=burst_type;
                                arvalid=1;
                                mmu_state<=MMU_DISABLED_WAIT_FOR_ARREADY; 
                            end
                            else//write
                            begin
                                awaddr={4'b0000,virtual_address};
                                awsize=2'b10;
                                awlen=transfer_length;
                                awburst=burst_type;
                                awvalid=1;
                                mmu_state<=MMU_DISABLED_WAIT_FOR_AWREADY;
                            end
                        end
                        else
                        begin
                            mmu_state<=MMU_IDLE_STATE;
                        end
                    end
                end
                MMU_CHECK_IN_TLB:
                begin
                    TLB_enable_RW<=0;
                    if(TLB_hit)
                    begin
                        physical_address<=TLB_physical_address;
                        mmu_state<=MMU_IDLE_STATE;
                    end
                    else
                    begin
                        araddr<={TTBR[27:16],virtual_address[27:14],2'b00};//descriptor of first address
                        arsize<=2'b10;//32 bits
                        arlen<=1;
                        arburst<=1;
                        arvalid<=1;
                        mmu_state<=WAIT_FOR_ARREADY;
                    end
                end
                WAIT_FOR_ARREADY:
                begin
                    if(arready)
                    begin
                        mmu_state<=WAIT_FOR_FIRST_DESCRIPTOR;
                        arvalid<=0;
                        rready=1;
                    end
                    else
                    begin
                        mmu_state<=WAIT_FOR_ARREADY;
                    end
                end
                WAIT_FOR_FIRST_DESCRIPTOR:
                begin
                    if(rvalid)
                    begin
                        first_descriptor<=rdata;
                        if(rdata[1:0]==2'b10)//a section
                        begin
                            physical_address<={rdata[28:27],rdata[26:23],rdata[22:21],virtual_address[13:0]};
                            TLB_virtual_address=virtual_address;
                            TLB_physical_address_input={rdata[28:27],rdata[26:23],rdata[22:21],virtual_address[13:0]};
                            TLB_properties_input={2'b00,rdata[11:10],4'b0000};//rdata[11:10] are access permissions
                            TLB_enable_RW=1;
                            TLB_read=0;
                            mmu_state<=WRITE_BACK_IN_TLB;
                            rready=0;
                        end
                        else if(rdata[1:0]==2'b01)//a page
                        begin
                            araddr={rdata[27:10],virtual_address[13:10],2'b00};//address of a second level descriptor
                            arsize=2'b10;
                            arlen=1;
                            arburst=2'b01;
                            arvalid=1;
                            mmu_state<=WAIT_FOR_ARREADY2;
                            rready=0;
                        end
                        else//raise a fault
                        begin
                            fault_status_register=4'b0011;//translation fault
                            fault_address_register={4'b0000,virtual_address};
                            mmu_state<=MMU_IDLE_STATE;
                            arvalid<=0;
                            rready=0;
                        end
                        
                    end
                end
                WAIT_FOR_ARREADY2:
                begin
                    if(arready)
                    begin
                        mmu_state<=WAIT_FOR_SECOND_DESCRIPTOR;
                        arvalid<=0;
                        rready=1;
                    end
                    else
                    begin
                        mmu_state<=WAIT_FOR_ARREADY2;
                    end
                end
                WAIT_FOR_SECOND_DESCRIPTOR:
                begin
                    if(rvalid)
                    begin
                        rready=0;
                        if(rdata[1:0]==2'b10)//a small page
                        begin
                            physical_address<={rdata[23:12],virtual_address[9:0]};
                            TLB_virtual_address=virtual_address;
                            TLB_physical_address_input={rdata[23:12],virtual_address[9:0]};
                            TLB_properties_input={2'b01,rdata[11:10],4'b0000};//rdata[11:10] are access permissions
                            TLB_enable_RW=1;
                            TLB_read=0;
                            mmu_state<=WRITE_BACK_IN_TLB;
                            
                        end
                        else if(rdata[1:0]==2'b01)//a large  page
                        begin
                            physical_address<={rdata[23:16],virtual_address[13:0]};
                            mmu_state<=MMU_IDLE_STATE;
                        end
                        else//a fault
                        begin
                            fault_status_register=4'b0011;//translation fault
                            fault_address_register={4'b0000,virtual_address};
                            mmu_state<=MMU_IDLE_STATE;
                        end
                    end
                    else
                    begin
                        mmu_state<=WAIT_FOR_SECOND_DESCRIPTOR;
                    end
                end
                WRITE_BACK_IN_TLB:
                begin
                    TLB_enable_RW<=0;
                    TLB_read<=0;
                    
                    //cache signals
                    cache_address=physical_address;
                    cache_read=1;
                    cache_enable_RW=1; 
                    mmu_state<=WAIT_FOR_CLK_CYCLE;
                end
                MMU_DISABLED_WAIT_FOR_ARREADY:
                begin
                    if(arready==1)
                    begin
                        mmu_state<=MMU_DISABLED_WAIT_FOR_RVALID;
                        arvalid=0;
                    end
                    else
                    begin
                        mmu_state<=MMU_DISABLED_WAIT_FOR_ARREADY;
                    end
                end
                MMU_DISABLED_WAIT_FOR_RVALID:
                begin
                    if(rvalid)
                    begin
                        data_out<=rdata;
                        mmu_state<=MMU_IDLE_STATE;
                        rready=0;
                    end
                    else
                    begin
                        mmu_state<=MMU_DISABLED_WAIT_FOR_RVALID;
                    end
                end
                MMU_DISABLED_WAIT_FOR_AWREADY:
                begin
                    if(awready)
                    begin
                        awvalid=0;
                        mmu_state<=MMU_DISABLED_WAIT_FOR_WREADY;
                    end
                    else
                    begin
                        mmu_state<=MMU_DISABLED_WAIT_FOR_AWREADY;
                    end
                end
                MMU_DISABLED_WAIT_FOR_WREADY:
                begin
                    if(wready)
                    begin
                        
                        if(no_of_wr_transfers<awlen)
                        begin
                            no_of_wr_transfers<=no_of_wr_transfers+1;
                            wdata=data_in;
                            wstrb=4'b1111;
                            wvalid=1;
                            if(no_of_wr_transfers==awlen-1)
                            begin
                                wlast=1;
                            end
                            mmu_state<=MMU_DISABLED_WAIT_FOR_WREADY;
                            
                        end
                        else
                        begin
                            mmu_state<=MMU_DISABLED_WAIT_FOR_BVALID;
                            wvalid<=0;
                            wdata=0;
                            wstrb=0;
                            bready=1;
                            wlast=0;
                            no_of_wr_transfers=0;
                            
                        end
                        
                    end
                    else
                    begin
                        mmu_state<=MMU_DISABLED_WAIT_FOR_WREADY;
                    end
                end
                MMU_DISABLED_WAIT_FOR_BVALID:
                begin
                    if(bvalid)
                    begin
                        bready=0;
                        mmu_state<=MMU_IDLE_STATE;
                    end
                    else
                    begin
                        mmu_state<=MMU_DISABLED_WAIT_FOR_BVALID;
                    end
                    
                end
                WAIT_FOR_CLK_CYCLE:
                begin
                    cache_enable_RW=0;
                    mmu_state<=CHECK_FOR_CACHE_HIT;
                end
                CHECK_FOR_CACHE_HIT:
                begin
                    if(cache_hit)
                    begin
                        if(enable_RW)
                        begin
                            if(read)
                            begin
                                data_out<=cache_data_out;
                                mmu_state=MMU_IDLE_STATE;
                            end
                            else//writes we will handle later
                            begin
                                
                            end
                        end
                        else
                        begin
                            mmu_state=MMU_IDLE_STATE;
                        end
                    end
                    else
                    begin
                        araddr<=physical_address;
                        arlen<=4'b1000;
                        arsize<=2'b10;
                        arburst<=2'b10;//wrapping burst
                        arvalid<=1;
                        mmu_state<=CACHE_ADDRESS_ON_BUS;
                        
                    end
                end
                CACHE_ADDRESS_ON_BUS:
                begin
                    if(arready)
                    begin
                        arvalid=0;
                        rready=1;
                        mmu_state<=WAIT_FOR_CACHE_DATA;
                    end
                    else
                    begin
                        
                        mmu_state<=CACHE_ADDRESS_ON_BUS;
                    end     
                end
                WAIT_FOR_CACHE_DATA:
                begin
                    if(rvalid)
                    begin
                        if(no_of_cache_transfers==0)
                        begin
                            cache_address=physical_address;
                        end
                        else
                        begin
                            cache_address=cache_address+4;
                        end
                        cache_read=0;
                        cache_enable_RW=1;
                        cache_data_in=rdata;
                        data_out=rdata;
                        rready=0;
                        mmu_state<=CACHE_FILL;
                        no_of_cache_transfers=no_of_cache_transfers+1;
                    end
                    else
                    begin
                        cache_read=0;
                        cache_enable_RW=0;
                        mmu_state<=WAIT_FOR_CACHE_DATA;
                    end
                end
                CACHE_FILL:
                begin
                    cache_enable_RW=0;
                    if(no_of_cache_transfers<8)
                    begin
                        rready=1;
                        mmu_state=WAIT_FOR_CACHE_DATA;
                    end
                    else
                    begin
                        mmu_state=MMU_IDLE_STATE;
                    end
                end
                WAIT_FOR_CLK_CYCLE_FOR_WRITE:
                begin
                    cache_enable_RW<=0;
                    mmu_state=CHECK_FOR_CACHE_HIT_WRITE;
                end
                CHECK_FOR_CACHE_HIT_WRITE://and write if there is a cache hit
                begin
                    if(cache_hit)
                    begin
                    end
                    else
                    begin
                        awaddr<=physical_address;
                        awlen<=1;
                        awsize<=2'b10;
                        awvalid<=1;
                        awburst<=2'b10;
                        mmu_state<=WAIT_FOR_AWADDRESS_TRANSFER;
                    end
                end
                WAIT_FOR_AWADDRESS_TRANSFER:
                begin
                    if(awready)
                    begin
                        awvalid=0;
                        wdata<=data_in;
                        wvalid<=1;
                        mmu_state<=WAIT_FOR_WREADY_TO_TRANSFER;
                    end
                    else
                    begin
                        mmu_state<=WAIT_FOR_AWADDRESS_TRANSFER;
                    end
                end
                WAIT_FOR_WREADY_TO_TRANSFER:
                begin
                    if(wready)
                    begin
                        wvalid=0;
                        bready=1;
                        mmu_state<=WAIT_FOR_WRESPONSE;
                    end
                    else
                    begin
                        mmu_state<=WAIT_FOR_WREADY_TO_TRANSFER;
                    end
                end
                WAIT_FOR_WRESPONSE:
                begin
                    if(bvalid)
                    begin
                        bready=0;
                        mmu_state<=MMU_IDLE_STATE;
                    end
                    else
                    begin
                        mmu_state<=WAIT_FOR_WRESPONSE;
                    end
                end
            endcase
        end
    end
    
    
    
    
    
endmodule
