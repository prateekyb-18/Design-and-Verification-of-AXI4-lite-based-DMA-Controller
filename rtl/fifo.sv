`timescale 1ns/1ps
module fifo #(
       parameter data_width=32,
       parameter depth=16)
      (input logic clk,
       input logic rst,
       input logic wrt_en,
       input logic rd_en,
       input logic[data_width-1:0]wrt_data,
       output logic[data_width-1:0]rd_data,
       output logic full,
       output logic empty);
localparam addr_width=$clog2(depth);
logic[data_width-1:0]mem[0:depth-1];
logic[addr_width:0]count;
logic [$clog2(depth)-1:0]wrt_ptr;
logic [$clog2(depth)-1:0]rd_ptr;

assign full=(count==depth);
assign empty=(count==0);

always_ff @(posedge clk) begin
    if(rst) begin
       wrt_ptr<='0;
       rd_ptr<='0;
       count<='0;
       rd_data<='0;
    end
    else begin
       if(wrt_en && !full) begin
       mem[wrt_ptr]<=wrt_data;
       wrt_ptr<=wrt_ptr+1;
       count<=count+1;
       end
       
       if(rd_en && !empty) begin
       rd_data<=mem[rd_ptr];
       rd_ptr<=rd_ptr+1 ;
       count<=count-1;
       end
    end
end
endmodule
    
