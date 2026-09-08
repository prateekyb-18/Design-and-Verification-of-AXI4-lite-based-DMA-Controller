module read_master_tb;

parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter BURST_LEN  = 4;

// Testbench Signals

logic clk;
logic rst;

logic read_start;

logic [ADDR_WIDTH-1:0] src_addr;

logic fifo_full;

logic fifo_wr_en;
logic [DATA_WIDTH-1:0] fifo_wr_data;

// AXI AR Channel

logic [ADDR_WIDTH-1:0] araddr;
logic [7:0] arlen;
logic [2:0] arsize;
logic arvalid;
logic arready;

// AXI R Channel

logic [DATA_WIDTH-1:0] rdata;
logic rvalid;
logic rlast;
logic rready;

// FSM

logic read_done;

// Debug

logic [1:0] state_dbg;

integer pass_count;
integer fail_count;


// State Encoding


localparam IDLE      = 0;
localparam SEND_AR   = 1;
localparam READ_DATA = 2;
localparam DONE      = 3;

//////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////

read_master #(

    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .BURST_LEN(BURST_LEN)

)dut(

    .clk(clk),
    .rst(rst),
    .read_start(read_start),
    .src_addr(src_addr),
    .fifo_full(fifo_full),
    .fifo_wr_en(fifo_wr_en),
    .fifo_wr_data(fifo_wr_data),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arvalid(arvalid),
    .arready(arready),
    .rdata(rdata),
    .rvalid(rvalid),
    .rlast(rlast),
    .rready(rready),
    .read_done(read_done),
    .state_dbg(state_dbg)

);


// Clock


always #5 clk = ~clk;

// Reset Task

task reset_dut();

begin

    rst = 0;

    read_start = 0;

    src_addr = 32'h1000;

    fifo_full = 0;

    arready = 0;

    rdata = 0;
    rvalid = 0;
    rlast = 0;

    repeat(2) @(posedge clk);

    rst = 1;

    @(posedge clk);

end

endtask

//////////////////////////////////////////////////
// Check State
//////////////////////////////////////////////////

task check_state(

input logic [1:0] expected,
input string test_name

);

begin

    if(state_dbg == expected)

    begin

        pass_count++;

        $display("[PASS] %s",test_name);

    end

    else

    begin

        fail_count++;

        $error("[FAIL] %s Expected=%0d Actual=%0d",
               test_name,
               expected,
               state_dbg);

    end

end

endtask

//////////////////////////////////////////////////
// Check Signal
//////////////////////////////////////////////////

task check_signal(

input logic actual,
input logic expected,
input string test_name

);

begin

    if(actual==expected)

    begin

        pass_count++;

        $display("[PASS] %s",test_name);

    end

    else

    begin

        fail_count++;

        $error("[FAIL] %s",test_name);

    end

end

endtask
//////////////////////////////////////////////////
// Main Test
//////////////////////////////////////////////////

initial
begin

    clk = 0;

    pass_count = 0;
    fail_count = 0;

        // RESET TEST
    

    reset_dut();

    check_state(IDLE,"RESET");

    check_signal(arvalid,0,"RESET_ARVALID");

    check_signal(rready,0,"RESET_RREADY");

    check_signal(read_done,0,"RESET_READ_DONE");

    
    // START READ
    

    read_start = 1;

    @(posedge clk);

    check_state(SEND_AR,"SEND_AR");

    check_signal(arvalid,1,"ARVALID_ASSERTED");

    
    // ARREADY STALL
    

    arready = 0;

    repeat(3)
        @(posedge clk);

    check_state(SEND_AR,"ARREADY_STALL");

  
    // ADDRESS HANDSHAKE
    

    arready = 1;

    @(posedge clk);

    check_state(READ_DATA,"READ_DATA");

  
    // FIRST DATA BEAT
   

    rvalid = 1;
    rlast  = 0;
    fifo_full = 0;

    rdata = 32'h11111111;

    @(posedge clk);

    check_signal(rready,1,"RREADY_HIGH");

    check_signal(fifo_wr_en,1,"FIFO_WRITE_ENABLE");

    if(fifo_wr_data == 32'h11111111)

    begin
        pass_count++;
        $display("[PASS] FIFO_DATA_BEAT1");
    end

    else

    begin
        fail_count++;
        $error("[FAIL] FIFO_DATA_BEAT1");
    end;

    // SECOND DATA BEAT
   

    rdata = 32'h22222222;

    @(posedge clk);

    if(fifo_wr_data == 32'h22222222)

    begin
        pass_count++;
        $display("[PASS] FIFO_DATA_BEAT2");
    end

    else

    begin
        fail_count++;
        $error("[FAIL] FIFO_DATA_BEAT2");
    end;

   
    // FIFO FULL STALL
  

    fifo_full = 1;

    @(posedge clk);

    check_state(READ_DATA,"FIFO_FULL_STALL");

    check_signal(rready,0,"RREADY_LOW");

    check_signal(fifo_wr_en,0,"FIFO_WRITE_STOPPED");

  
    // RESUME TRANSFER
  

    fifo_full = 0;

    rdata = 32'h33333333;

    @(posedge clk);

    check_signal(rready,1,"TRANSFER_RESUME");

    if(fifo_wr_data == 32'h33333333)

    begin
        pass_count++;
        $display("[PASS] FIFO_DATA_BEAT3");
    end

    else

    begin
        fail_count++;
        $error("[FAIL] FIFO_DATA_BEAT3");
    end;
//////////////////////////////////////////////
    // FOURTH (LAST) DATA BEAT
    //////////////////////////////////////////////
    fifo_full=0;
    rdata = 32'h44444444;
        
    rlast = 1;
// if(fifo_wr_data == 32'h44444444)
  //   begin
    //     pass_count++;
      //   $display("[PASS] FIFO_DATA_BEAT4");
    // end
     
    // else
    // begin
      //   fail_count++;
        // $display("fifo_wr_data=%h",fifo_wr_data);
        // $display("rdata=%h",rdata);
        // $display("state=%0d",state_dbg);
        // $error("[FAIL] FIFO_DATA_BEAT4");
    // end


    @(posedge clk);

    //////////////////////////////////////////////
    // DONE STATE
    //////////////////////////////////////////////
    //////////////////////////////////////////////
    // RETURN TO IDLE
    //////////////////////////////////////////////

    rvalid = 0;
    rlast  = 0;
    arready = 0;
    read_start = 0;

    @(posedge clk);

    check_state(IDLE,"RETURN_TO_IDLE");

    check_signal(read_done,0,"READ_DONE_DEASSERT");

    //////////////////////////////////////////////
    // SUMMARY
    //////////////////////////////////////////////

    $display("==================================");

    $display("PASS COUNT = %0d",pass_count);

    $display("FAIL COUNT = %0d",fail_count);

    $display("==================================");

    $finish;

end

//////////////////////////////////////////////////
// Waveform Dump
//////////////////////////////////////////////////

initial

begin

    $dumpfile("read_master.vcd");
    $dumpvars(0,read_master_tb);

end

endmodule
