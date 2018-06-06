`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2018 11:59:44
// Design Name: 
// Module Name: MMU_TB_new
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


module mmu_TB_new(

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
    wire[17:0] physical_address;
    reg[31:0] data_in;
    wire[31:0] data_out;
    reg[3:0] transfer_length;
    reg[1:0] burst_type;
    
    mmu Mmemory_Management_Unit(
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
            transfer_length=0;
            burst_type=0;
        end
        initial
        begin
            #9000 $finish;
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
                virtual_address=28'h0002FF8;
                data_in=32'h20000C06;// section descriptor
                transfer_length=1;
                burst_type=1;
            
            #40 enable_RW=0;
            
            #240
            
            #40 enable_RW=1;
                read=0;
                virtual_address=28'h00002AFC;
                data_in=32'h0C000001;// page descriptor
            
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
                virtual_address=28'h00003038;
                data_in=32'h20000C05;//  second page descriptor
            
            #40 enable_RW=0;
            
            
            //cache address writing
            #240 
            #40 enable_RW=1;
                read=0;
                virtual_address=28'h000AABC;
                data_in=32'h32333435;
                transfer_length=8;
                burst_type=2'b10;
            #40 enable_RW=0;
            
            
            #600
            //cache address writing
            #240 
            #40 enable_RW=1;
                read=0;
                virtual_address=28'h0008ABC;
                data_in=32'h22232425;
                transfer_length=8;
                burst_type=2'b10;
            #40 enable_RW=0;
            
            #600
            //this is where the section is checked
            #240 mmu_enable=1;
       
            #40 virtual_address=28'h2FFAABC;
                read=1;
                enable_RW=1;
                
            #40 enable_RW=0;
                read=0;
                
                
           //test for a condition where the data exists in tlb for the first access
           #2000
           #40 virtual_address=28'h2FFAABC;
               read=1;
               enable_RW=1;
               
           #40 enable_RW=0;
               read=0;

           #1000
           //for a large page
           #40 virtual_address=28'h2AFFABC;
               read=1;
               enable_RW=1;
               
           #40 enable_RW=0;
               read=0;     
                               
                
        end    
endmodule
