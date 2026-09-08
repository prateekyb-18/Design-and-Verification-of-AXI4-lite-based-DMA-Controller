`timescale 1ns/1ps
module fifo_tb;
parameter data_width=32;
parameter depth=16;

logic clk;
logic rst;
logic wrt_en;
logic rd_en;
logic [data_width-1:0]wrt_data;
logic [data_width-1:0]rd_data;
logic full;
logic empty;
int error_count=0;

fifo #(
.data_width(data_width),.depth(depth))
dut (.clk(clk),.rst(rst),.wrt_en(wrt_en),.rd_en(rd_en),.wrt_data(wrt_data),
.rd_data(rd_data),.full(full),.empty(empty));

initial clk=0;
always #5 clk=~clk;

initial begin
$dumpfile("wave/fifo.vcd");
$dumpvars(0,fifo_tb);
end

logic [data_width-1:0]ref_queue[$];

task do_write(input logic [data_width-1:0] data); begin
@(negedge clk);
wrt_en=1;
rd_en=0;
wrt_data=data;

@(negedge clk);
wrt_en=0;

@(negedge clk);
if(!full)
ref_queue.push_back(data);
end
endtask

task do_read();
logic [data_width-1:0]expected; begin
@(negedge clk);
wrt_en=0;
rd_en=1;

@(negedge clk);
rd_en=0;

@(negedge clk);
if(!empty) begin
expected=ref_queue.pop_front();
if(rd_data!==expected) begin
$error("Data Mismacth! Expected=%0d, Got=%0d",expected,rd_data);
error_count++;
end
end
end
endtask

property no_overflow_prop;
@(posedge clk) disable iff (rst) !(full && wrt_en && !rd_en);
endproperty

assert property(no_overflow_prop)
else begin
$error("Overflow detected");
error_count++;
end

property no_underflow_prop;
@(posedge clk) disable iff (rst) !(empty && rd_en && !wrt_en);
endproperty

assert property(no_underflow_prop)
else begin
$error("Underflow detected");
error_count++;
end

property full_flag_correct;
@(posedge clk) disable iff (rst) (ref_queue.size()==depth)|->full;
endproperty

assert property(full_flag_correct)
else begin
$error("Full Flag Incorrect");
error_count++;
end

property empty_flag_correct;
@(posedge clk) disable iff (rst) (ref_queue.size()==0)|->empty;
endproperty

assert property(empty_flag_correct)
else begin
$error("Empty Flag Incorrect");
error_count++;
end

cover property(@(posedge clk) full);
cover property(@(posedge clk) empty);


initial begin
wrt_en=0;
rd_en=0;
wrt_data=0;
rst=0;

repeat(3) @(posedge clk);
rst=0;

do_write(10);
do_write(20);
do_write(30);

do_read();
do_read();

repeat(depth)

do_write(byte'($urandom));

repeat(depth)
do_read();

repeat(depth+2)
do_write(byte'($urandom));

repeat(depth+2)
do_read();

@(posedge clk);
wrt_en=1;
rd_en=1;
wrt_data=55;

@(posedge clk);
wrt_en=0;
rd_en=0;

#20;

if(error_count==0)
$display("\n************* TEST PASSED ************\n");
else
$display("\n************* TEST FAILED:%0d ERRORS ************\n",error_count);
$finish;
end
initial begin

    $dumpfile("fifo.vcd");
    $dumpvars(0,fifo_tb);

end
endmodule
