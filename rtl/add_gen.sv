`timescale 1ns/1ps
module add_gen(
input logic clk,
input logic rst,
input logic [31:0]src_addr_in,
input logic [31:0]dst_addr_in,
input logic [31:0]length_in,
input logic update_addr,
output logic transfer_done,
output logic [31:0]remaining_length,
input logic [31:0]burst_bytes,
input logic load_config,
output logic [31:0]current_src_addr,
output logic [31:0]current_dst_addr);

always_ff @(posedge clk or negedge rst)
begin
 if(!rst)
 begin
  current_src_addr<=0;
  current_dst_addr<=0;
  remaining_length<=0;
end
 else if(load_config)
 begin
  current_src_addr<=src_addr_in;
  current_dst_addr<=dst_addr_in;
  remaining_length<=length_in;
 end
 else if(update_addr)
 begin
  current_src_addr<=current_src_addr+burst_bytes;
  current_dst_addr<= current_dst_addr+burst_bytes;
  if(remaining_length<=burst_bytes)
    begin
    remaining_length<=0;
    end
  else
    begin
    remaining_length<=remaining_length-burst_bytes;
  end
end
end

always_comb
begin
 transfer_done=0;
 if(remaining_length==0)
  transfer_done=1;
end

endmodule
