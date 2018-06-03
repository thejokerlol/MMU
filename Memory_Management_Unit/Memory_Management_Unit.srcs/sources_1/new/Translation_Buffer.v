`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2018 05:35:08
// Design Name: 
// Module Name: Translation_Buffer
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

//32 entries in the tlb, fully associative mapping

module Translation_Buffer(
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
    
    input clk;
    input reset;
    input[27:0] virtual_address;
    input read;
    input enable_RW;
    input[23:0] physical_address_input;
    input[7:0] properties_input;
    output reg[23:0] physical_address;
    output reg[7:0] properties;
    output reg hit;
    
    reg[31:0] valid;
    reg[27:10] virtual_page_memory[0:31];
    reg[23:10] physical_page_memory[0:31];
    reg[7:0] properties_memory[0:31];
    
    reg[7:0] time_stamp;
    
    reg[7:0] LRU_count_register[0:31];//a register holding the time stamp
    reg[4:0] LRU_location;
    
    reg[0:31] comp_output;
    
    reg[4:0] decoder_output;
    
    //not so trivial
    genvar tag_no;
    generate
        for(tag_no=0;tag_no<32;tag_no=tag_no+1)
        begin
            always@(*)
            begin
                if(enable_RW && read && valid[tag_no]==1)
                begin
                    case(properties_memory[tag_no][7:6])
                        2'b00://a section 16k memory region
                        begin
                            if(virtual_address[27:14]==virtual_page_memory[tag_no][27:14])
                            begin
                                comp_output[tag_no]=1;
                            end
                            else
                            begin
                                comp_output[tag_no]=0;
                            end
                        end
                        2'b01://a small page 1k memory region
                        begin   
                            if(virtual_address[27:10]==virtual_page_memory[tag_no][27:10])
                            begin
                                comp_output[tag_no]=1;
                            end
                            else
                            begin
                                comp_output[tag_no]=0;
                            end
                        end
                        2'b10://a large page 4k memory regison
                        begin
                            if(virtual_address[27:12]==virtual_page_memory[tag_no][27:12])
                            begin
                                comp_output[tag_no]=1;
                            end
                            else
                            begin
                                comp_output[tag_no]=0;
                            end
                        end
                        2'b11://invalid
                        begin
                            comp_output[tag_no]=0;
                        end
                    endcase
                end
                else
                begin
                    comp_output[tag_no]=0;
                end
            end
        end
    endgenerate
    
    
    //code for hit
    always@(*)
    begin
        hit=0;
        if(comp_output!=0)
        begin
            hit=1;
        end
    end
    
    //code for decoder
    reg[5:0] count;
    always@(*)
    begin
        decoder_output=0;
        for(count=0;count<32;count=count+1)
        begin
            if(comp_output[count]==1)
            begin
                decoder_output=count;
            end
        end
    end
    
    //process block for time stamp for LRU implementation
    always@(posedge clk or negedge reset)
    begin
        if(!reset)
        begin
            time_stamp<=0;
        end
        else
        begin
            if(enable_RW)
            begin
                time_stamp<=time_stamp+1;
            end
        end
    end
    
    
    integer i;
    always@(posedge clk or negedge reset)
    begin
        if(!reset)
        begin
            for(i=0;i<32;i=i+1)
            begin
               valid[i]=0; 
            end
        end
        else
        begin
            if(enable_RW && !read)
            begin
                valid[LRU_location]=1;
            end
        end
        
    end
    
    always@(*)
    begin
        
        if(enable_RW && read && hit)
        begin
            case(properties_memory[decoder_output][7:6])
                2'b00://a section
                begin
                    physical_address={physical_page_memory[decoder_output][23:14],virtual_address[13:0]};
                    
                end
                2'b01://a small page
                begin
                    physical_address={physical_page_memory[decoder_output][23:10],virtual_address[9:0]};
                end
                2'b10://a large page
                begin
                    physical_address={physical_page_memory[decoder_output][23:12],virtual_address[11:0]};
                end
                2'b11://not used
                begin
                    physical_address=0;
                end
            endcase
            properties=properties_memory[decoder_output];
        end
        else
        begin
            physical_address=0;
            properties=0;
        end
    end
    
    reg[5:0] LRU_counter;
    always@(posedge clk or negedge reset)
    begin
        if(!reset)
        begin
            for(LRU_counter=0;LRU_counter<32;LRU_counter=LRU_counter+1)
            begin
                LRU_count_register[LRU_counter]=0;
            end
        end
        else
        begin
            if(enable_RW)
            begin
                if(LRU_count_register[decoder_output]!=255)
                begin
                    LRU_count_register[decoder_output]<=time_stamp;
                end
            end
        end
    end
    
    always@(posedge clk)
    begin
        if(enable_RW && !read)
        begin
           virtual_page_memory[LRU_location]<=virtual_address[27:10];
           properties_memory[LRU_location]<=properties_input;
           physical_page_memory[LRU_location]<=physical_address_input[23:10];
        end
    end
    
    
    //calculation of LRU_location
    
        //LRU LOGIC
 reg[4:0] LRU_no[0:30];
 reg[7:0] LRU_value[0:30];
 
 genvar m;
 generate
  for(m=0;m<31;m=m+1)
  begin
      if(m==0)
      begin
          always@(*)
          begin
            if(LRU_count_register[0]<LRU_count_register[1])
            begin
                LRU_no[0]=0;
                LRU_value[0]=LRU_count_register[0];
            end
            else
            begin
                LRU_no[0]=1;
                LRU_value[0]=LRU_count_register[1];
            end
          end
      end
      else
      begin
          always@(*)
          begin
            if(LRU_value[m-1]<LRU_count_register[m+1])
            begin
                LRU_value[m]=LRU_value[m-1];
                LRU_no[m]=LRU_no[m-1];
            end
            else
            begin
                LRU_value[m]=LRU_count_register[m+1];
                LRU_no[m]=m+1;
            end
          end  
      end
  end
 endgenerate
    
always@(*)
begin
    LRU_location=LRU_no[30];
end    
    
    
endmodule
