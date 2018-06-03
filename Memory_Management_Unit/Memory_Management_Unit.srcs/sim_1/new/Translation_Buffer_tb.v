`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2018 17:38:13
// Design Name: 
// Module Name: Translation_Buffer_tb
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


module Translation_Buffer_tb(

    );
    reg clk;
    reg reset;
    reg[27:0] virtual_address;
    reg[23:0] physical_address_input;
    reg[7:0] properties_input;
    reg read;
    reg enable_RW;
    wire[23:0] physical_address;
    wire[7:0] properties;
    wire hit;
    
    
    Translation_Buffer TB(
        clk,
        reset,
        virtual_address,
        physical_address_input,
        properties_input,
        read,
        enable_RW,
        physical_address,
        properties,
        hit
        );
        
        
        initial
        begin
            clk=0;
            reset=1;
            virtual_address=0;
            physical_address_input=0;
            read=0;
            enable_RW=0;
        end
        
        always
            #20 clk=!clk;
            
       initial
        #1000 $finish;
        
        
       initial
       begin
            #120
            #4 reset=0;
            #4 reset=1;
            
            //try to read a virtual address
            #40 virtual_address=28'hFFFFABC;
                read=1;
                enable_RW=1;
            
            
            #40 enable_RW=0;
            //write a virtual address
            #40 virtual_address=28'hFFFFABC;
                physical_address_input=24'hAFFABC;
                properties_input=8'h0F;
                read=0;
                enable_RW=1;
                
            
            #40 enable_RW=0;
            //try to read it again
            #40 virtual_address=28'hFFFFABB;
                read=1;
                enable_RW=1;
            
            #40 enable_RW=0;
            //try a new virtual address
            
            
       end
        
endmodule
