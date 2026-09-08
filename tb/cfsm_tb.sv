module cfsm_tb;

logic clk;
logic rst_n;

logic start;

logic fifo_empty;
logic fifo_full;

logic read_done;
logic write_done;

logic transfer_done;

logic load_config;
logic read_start;
logic write_start;
logic update_addr;
logic dma_done;

logic [3:0] state_dbg;

integer pass_count;
integer fail_count;

// State Encoding


localparam IDLE            = 0;
localparam LOAD_CONFIG     = 1;
localparam WAIT_FIFO_SPACE = 2;
localparam READ_BURST      = 3;
localparam WAIT_READ       = 4;
localparam WAIT_FIFO_DATA  = 5;
localparam WRITE_BURST     = 6;
localparam CHECK_DONE      = 7;
localparam DONE            = 8;

// DUT


cfsm dut (.clk(clk),.rst_n(rst_n),.start(start),

    .fifo_empty(fifo_empty),
    .fifo_full(fifo_full),
    .read_done(read_done),
    .write_done(write_done),
    .transfer_done(transfer_done),
    .load_config(load_config),
    .read_start(read_start),
    .write_start(write_start),
    .update_addr(update_addr),
    .dma_done(dma_done),
    .state_dbg(state_dbg)

);


// Clock

always #5 clk = ~clk;

//////////////////////////////////////////////////
// Reset Task
//////////////////////////////////////////////////

task reset_dut();
begin

    rst_n = 0;

    start = 0;

    fifo_empty = 0;
    fifo_full  = 0;

    read_done = 0;
    write_done = 0;

    transfer_done = 0;

    repeat(2) @(posedge clk);

    rst_n = 1;

    @(posedge clk);

end
endtask

//////////////////////////////////////////////////
// State Check Task
//////////////////////////////////////////////////

task check_state(
    input logic [3:0] expected,
    input string test_name
);
begin

    if(state_dbg == expected)
    begin
        pass_count++;
        $display("[PASS] %s", test_name);
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
// Signal Check Task
//////////////////////////////////////////////////

task check_signal(
    input logic actual,
    input logic expected,
    input string test_name
);
begin

    if(actual == expected)
    begin
        pass_count++;
        $display("[PASS] %s", test_name);
    end

    else
    begin
        fail_count++;

        $error("[FAIL] %s", test_name);
    end

end
endtask

//////////////////////////////////////////////////
// Main Test
//////////////////////////////////////////////////

initial begin

    clk = 0;

    pass_count = 0;
    fail_count = 0;

    //////////////////////////////////////////////
    // RESET TEST
    //////////////////////////////////////////////

    reset_dut();

    check_state(IDLE,"RESET");

    //////////////////////////////////////////////
    // START DMA
    //////////////////////////////////////////////

    start = 1;
    @(posedge clk);
    
    
    check_state(LOAD_CONFIG,"LOAD_CONFIG");
    check_signal(load_config,1,"LOAD_CONFIG_OUT");

    //////////////////////////////////////////////
    // WAIT_FIFO_SPACE
    //////////////////////////////////////////////
    
    @(posedge clk);

    check_state(WAIT_FIFO_SPACE,
                "WAIT_FIFO_SPACE");

    //////////////////////////////////////////////
    // FIFO FULL STALL
    //////////////////////////////////////////////

    fifo_full = 1;

    repeat(3)
        @(posedge clk);

    check_state(WAIT_FIFO_SPACE,
                "FIFO_FULL_STALL");

    //////////////////////////////////////////////
    // START READ
    //////////////////////////////////////////////

    fifo_full = 0;
    @(posedge clk);
    check_state(READ_BURST,
                "READ_BURST");

    check_signal(read_start,
                 1,
                 "READ_START");

    @(posedge clk);

    check_state(WAIT_READ,
                "WAIT_READ");

    //////////////////////////////////////////////
    // READ WAIT
    //////////////////////////////////////////////

    repeat(2)
        @(posedge clk);

    check_state(WAIT_READ,
                "WAIT_READ_STALL");

    //////////////////////////////////////////////
    // READ COMPLETE
    //////////////////////////////////////////////

    read_done = 1;

    @(posedge clk);
    check_state(WAIT_FIFO_DATA,
                "WAIT_FIFO_DATA");

    //////////////////////////////////////////////
    // FIFO EMPTY STALL
    //////////////////////////////////////////////

    fifo_empty = 1;

    repeat(3)
        @(posedge clk);

    check_state(WAIT_FIFO_DATA,
                "FIFO_EMPTY_STALL");

    //////////////////////////////////////////////
    // START WRITE
    //////////////////////////////////////////////

    fifo_empty = 0;
    @(posedge clk);
  

    check_state(WRITE_BURST,
                "WRITE_BURST");

    check_signal(write_start,
                 1,
                 "WRITE_START");

    //////////////////////////////////////////////
    // WRITE COMPLETE
    //////////////////////////////////////////////

    write_done = 1;

    @(posedge clk);

    write_done = 0;

    check_state(CHECK_DONE,
                "CHECK_DONE");

    check_signal(update_addr,
                 1,
                 "UPDATE_ADDR");

    //////////////////////////////////////////////
    // LOOP BACK
    //////////////////////////////////////////////

    transfer_done = 0;
    @(posedge clk);
  

    check_state(WAIT_FIFO_SPACE,
                "LOOP_BACK");

    //////////////////////////////////////////////
    // FINAL TRANSFER PATH
    //////////////////////////////////////////////

    fifo_full = 0;

    @(posedge clk);
    @(posedge clk);

    read_done = 1;
    @(posedge clk);
    read_done = 0;

    fifo_empty = 0;

    @(posedge clk);

    write_done = 1;
    @(posedge clk);
    write_done = 0;

    transfer_done = 1;

    @(posedge clk);

    check_state(DONE,
                "DONE_STATE");

    check_signal(dma_done,
                 1,
                 "DMA_DONE");

    @(posedge clk);

    check_state(IDLE,
                "RETURN_IDLE");

    //////////////////////////////////////////////
    // SUMMARY
    //////////////////////////////////////////////

    $display("========================");
    $display("PASS COUNT = %0d",
              pass_count);

    $display("FAIL COUNT = %0d",
              fail_count);

    $display("========================");

    $finish;

end

//////////////////////////////////////////////////
// Waveforms
//////////////////////////////////////////////////

initial begin

    $dumpfile("cfsm.vcd");
    $dumpvars(0,cfsm_tb);

end

endmodule
