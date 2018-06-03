`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2018 13:22:55
// Design Name: 
// Module Name: mmu_TB
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


module mmu_TB(

    );
    reg clk;
    reg reset;
    reg mmu_enable;
    reg[27:0] virtual_address;
    reg read;
    reg TTBR_read;
    reg enable_RW;
    reg instruction;
    reg supervisor;
    wire[31:0] fault_address_register;
    wire[3:0] fault_status_register;
    wire[23:0] physical_address;
    reg[31:0] data_in;
    wire[31:0] data_out;
    
    mmu Mmemory_Management_Unit(
            clk,
            reset,
            mmu_enable,
            virtual_address,
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
        
        
        initial
        begin
            clk=0;
            reset=0;
            mmu_enable=0;
            virtual_address=0;
            read=0;
            enable_RW=0;
            instruction=0;//data access
            supervisor=0;//its an OS accessing the data
            data_in=0;
        end
        initial
        begin
            #4000 $finish;
        end
        
        always
            #20 clk=!clk;
            
        initial
        begin
            #100
            #4 reset=0;
            #4 reset=1;
            
            #40 enable_RW=1;
                read=0;
                virtual_address=28'd65532;
                data_in=32'h57e00002;// section descriptor
            
            #40 enable_RW=0;
            
            #240
            
            #40 enable_RW=1;
                read=0;
                virtual_address=28'h0000ffc;
                data_in=32'h00bf001;// page descriptor
            
            #40 enable_RW=0;
            
            #240
            
            #40 enable_RW=1;
                read=0;
                virtual_address=28'h0000ffc;
                data_in=32'h00bf001;// data at first page descriptor
            
            #40 enable_RW=0;
            
            #240
                        
            #40 enable_RW=1;
                read=0;
                virtual_address=28'h0000bf3c;
                data_in=32'h0007f002;//  second page descriptor
            
            #40 enable_RW=0;
            
            
            #240 mmu_enable=1;
       
            #40 virtual_address=28'hFFFFABC;
                read=1;
                enable_RW=1;
                
            #40 enable_RW=0;
                read=0;
                
                
           //test for a condition where the data exists in tlb
           #240
           #40 virtual_address=28'hFFFFAAA;
               read=1;
               enable_RW=1;
               
           #40 enable_RW=0;
               read=0;
               
           #320
           //for a small page
           #40 virtual_address=28'h0FFFFA8;
               read=1;
               enable_RW=1;
               
           #40 enable_RW=0;
               read=0;     
                               
                
        end    
endmodule
