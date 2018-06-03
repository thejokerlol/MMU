`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2018 03:23:13
// Design Name: 
// Module Name: compare_counts
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


module compare_counts(in1,in2,a1,a2,out,out1

    );
    parameter INPUT_LENGTH=6;
    parameter OUTPUT_SIZE=6;
    input[INPUT_LENGTH-1:0] in1;
    input[INPUT_LENGTH-1:0] in2;
    input[OUTPUT_SIZE-1:0] a1;
    input[OUTPUT_SIZE-1:0] a2;
    output reg[OUTPUT_SIZE-1:0] out;
    output reg[INPUT_LENGTH-1:0] out1;
    always@(*)
    begin
        if(in1<in2)
        begin
            out=a1;
            out1=in1;
        end
        else
        begin
            out=a2;
            out1=in2;
        end
    end
endmodule
