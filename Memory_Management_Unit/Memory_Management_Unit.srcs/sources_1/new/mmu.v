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
        virtual_address,
        read,
        enable_RW,
        instruction,//1 for instruction access and 0 for data access
        supervisor,
        fault_address_register,
        fault_status_register
    );
    
    input virtual_address;
    input read;
    input enable_RW;
    input instruction;
    input supervisor;
    output[31:0] fault_address_register;
    output[3:0] fault_status_register;
    
    
    
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
    
    
    
    
    
    
    
    
endmodule
