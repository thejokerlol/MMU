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
    reg[27:0] virtual_address;
    reg read;
    reg TTBR_read;
    reg enable_RW;
    reg instruction;
    reg supervisor;
    wire fault_address_register;
    wire fault_status_register;
    wire[23:0] physical_address;
    
    
    mmu Mmemory_Management_Unit(
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
        
        
        initial
        begin
            clk=0;
            reset=0;
            virtual_address=0;
            read=0;
            enable_RW=0;
            instruction=0;//data access
            supervisor=0;//its an OS accessing the data
        end
        initial
        begin
            #1200 $finish;
        end
        
        always
            #20 clk=!clk;
            
        initial
        begin
            #4 reset=0;
            #4 reset=1;
            
            
            #40 virtual_address=28'hFFFFABC;
                read=1;
                enable_RW=1;
        end    
endmodule
