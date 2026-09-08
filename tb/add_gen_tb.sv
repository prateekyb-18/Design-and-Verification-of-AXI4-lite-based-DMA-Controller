`timescale 1ns/1ps
module add_gen_tb;
logic clk;
logic rst;
logic load_config;
logic update_addr;
logic transfer_done;
logic [31:0]src_addr_in;
logic [31:0]dst_addr_in;
logic [31:0]length_in;
logic [31:0]remaining_length;
logic [31:0]current_src_addr;
logic [31:0]current_dst_addr;
integer pass_count;
integer fail_count;
logic [31:0] burst_bytes;

add_gen dut(.clk(clk),.rst(rst),.load_config(load_config),.update_addr
(update_addr),.burst_bytes(burst_bytes),.transfer_done(transfer_done),.src_addr_in(src_addr_in),
 .dst_addr_in(dst_addr_in),.length_in(length_in),.remaining_length
(remaining_length),. current_src_addr(current_src_addr),.current_dst_addr
(current_dst_addr));

always #5 clk=~clk;

task reset_dut();
begin
 rst=0;
 repeat(2);
 @(posedge clk);
 rst=1;
 @(posedge clk);
end
endtask

//check task

task Check_result(
input logic [31:0] actual,
input logic [31:0] expected,
input string test_name); 

begin

if (actual == expected)

begin

pass_count ++;

$display ("%s PASSED", test_name);

end

else begin

fail_count++;

$error ("%s Failed explected=%b,actual=%b", test_name, expected, actual);
end
end
endtask

initial begin

$dumpfile("wave/add_gen.vcd");
$dumpvars(0,add_gen_tb);
pass_count=0;

fail_count = 0;

clk=0;

reset_dut();

Check_result (current_src_addr,32'h0, "RESET -SRC");

Check_result (current_dst_addr, 32'h0, "RESET-DSTH");

Check_result (remaining_length, 32'h0, "RESET-Len");

//load config test

src_addr_in = 32'h1000;

dst_addr_in = 32'h2000;

length_in = 32'd100;

load_config=1;

@(posedge clk);

load_config=0;

Check_result (current_src_addr, 32'h1000, "LoadSRC");

Check_result(current_dst_addr, 32'h2000, "LoadDST");

Check_result(remaining_length, 32'd100, "LoadLEN");

// Single update test

burst_bytes = 32'd16;

update_addr = 1;


@(posedge clk);

update_addr = 0;
Check_result (current_src_addr, 32'h1010, "SINGLE-UPDATE-SRC");

Check_result(current_dst_addr, 32'h2010," SINGLE-UPDATE-DST");

Check_result(remaining_length, 32'd84, "SINGLE-UPDATE-LEN");


   


// Multiple update test

repeat (5)                                             
 begin

update_addr = 1;

@(posedge clk);

update_addr=0;

@(posedge clk);

end


Check_result (current_src_addr, 32'h1060, "MULTIPLE-UPDATE-SRC");

Check_result(current_dst_addr, 32'h2060," MULTIPLE-UPDATE-DST");

Check_result(remaining_length, 32'd4, "MULTIPLE-UPDATE-LEN");


// Final transfer test

burst_bytes = 32'd16;
update_addr=1;

@(posedge clk);
update_addr=0;

Check_result (current_src_addr, 32'h1070, "FINAL-TRANSFER-SRC");

Check_result(current_dst_addr, 32'h2070," FINAL-TRANSFER-DST");

Check_result(remaining_length, 32'd0, "FINAL-TRANSFER-LEN");


if(transfer_done)
pass_count++;
else
fail_count++;

$display("pass=%d",pass_count);
$display("fail=%d",fail_count);

$finish;
end
initial begin

    $dumpfile("add_gen.vcd");
    $dumpvars(0,add_gen_tb);

end
endmodule
