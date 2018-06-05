`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.06.2018 10:45:33
// Design Name: 
// Module Name: cache_tb
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


module cache_tb(

    );
    reg clk;
    reg address;
    reg reset;
    reg read;
    reg enable_RW;
    reg data_in;
    wire data_out;
    wire hit;
    
    cache(
    
        clk,
        address,
        reset,
        read,
        enable_RW,
        data_in,
        data_out,
        hit 
    
        );
endmodule
