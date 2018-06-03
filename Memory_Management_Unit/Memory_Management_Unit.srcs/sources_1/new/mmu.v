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
        virtual_address,
        read,
        TTBR_read,
        enable_RW,
        instruction,//1 for instruction access and 0 for data access
        supervisor,
        fault_address_register,
        fault_status_register,
        physical_address
    );
    
    input clk;
    input reset;
    input[27:0] virtual_address;
    input read;
    input TTBR_read;
    input enable_RW;
    input instruction;
    input supervisor;
    output reg[31:0] fault_address_register;
    output reg[3:0] fault_status_register;
    output reg[23:0] physical_address;
    
    
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
    reg[23:0] TLB_physical_address_input;
    reg[7:0] TLB_properties_input;
    reg TLB_read;
    reg TLB_enable_RW;
    wire[23:0] TLB_physical_address;
    wire[7:0] TLB_properties;
    wire TLB_hit;
    
    //mmu signals
    reg[2:0] mmu_state;
    reg[31:0] first_descriptor;
    reg[31:0] second_descriptor;
    parameter MMU_IDLE_STATE=3'b000;
    parameter MMU_CHECK_IN_TLB=3'b001;
    parameter WAIT_FOR_ARREADY=3'b010;
    parameter WAIT_FOR_FIRST_DESCRIPTOR=3'b011;
    parameter WAIT_FOR_ARREADY2=3'b100;
    parameter WAIT_FOR_SECOND_DESCRIPTOR=3'b101;
    parameter WRITE_BACK_IN_TLB=3'b110;
    
    
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
            ILB_physical_address_input,
            TLB_properties_input,
            TLB_read,
            TLB_enable_RW,
            TLB_physical_address,
            TLB_properties,
            TLB_hit
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
        end
        else
        begin
            case(mmu_state)
                MMU_IDLE_STATE:
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
                        araddr<={TTBR[27:16],virtual_address[27:14],2'b00};
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
                            physical_address<={rdata[30:20],virtual_address[13:0]};
                            mmu_state<=MMU_IDLE_STATE;
                            rready=0;
                        end
                        else if(rdata[1:0]==2'b01)//a page
                        begin
                            araddr={rdata[30:20],virtual_address[13:10],2'b00};
                            arsize=2'b10;
                            arlen=1;
                            arburst=2'b10;
                            arvalid=1;
                            mmu_state<=WAIT_FOR_ARREADY2;
                            rready=0;
                        end
                        else//raise a fault
                        begin
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
                            physical_address<={rdata[25:12],virtual_address[9:0]};
                            mmu_state<=MMU_IDLE_STATE;
                            
                        end
                        else if(rdata[1:0]==2'b01)//a large  page
                        begin
                            physical_address<={rdata[25:16],virtual_address[13:0]};
                            mmu_state<=MMU_IDLE_STATE;
                        end
                        else//a fault
                        begin
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
                    
                end
            endcase
        end
    end
    
    
    
    
    
endmodule
