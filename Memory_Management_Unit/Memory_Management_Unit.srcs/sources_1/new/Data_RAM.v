`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.06.2018 10:42:57
// Design Name: 
// Module Name: Data_RAM
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


module Data_RAM(clk,address,enable_RW,read,
    data_in,
    data_out

    );
    input clk;
    input[5:0] address;
    input enable_RW;
    input read;
    input[7:0] data_in;
    output reg[7:0] data_out;
    
    reg[7:0] data_mem[0:63];
    
    always@(posedge clk)
    begin
        if(enable_RW)
        begin
            if(read)
            begin
                data_out<=data_mem[address];
            end
            else
            begin
                data_mem[address]<=data_in;
            end
        end
    end
        
endmodule
