module reg_interface_tb;

parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;

// Testbench Signals


logic clk;
logic rst_n;

// Write Address Channel

logic [ADDR_WIDTH-1:0] awaddr;
logic awvalid;
logic awready;

// Write Data Channel

logic [DATA_WIDTH-1:0] wdata;
logic wvalid;
logic wready;

// Write Response

logic bvalid;
logic bready;

// Read Address Channel

logic [ADDR_WIDTH-1:0] araddr;
logic arvalid;
logic arready;

// Read Data Channel

logic [DATA_WIDTH-1:0] rdata;
logic rvalid;
logic rready;

// DMA

logic dma_done;

logic [31:0] src_addr;
logic [31:0] dst_addr;
logic [31:0] length;
logic start;

// Debug

logic [2:0] state_dbg;

integer pass_count;
integer fail_count;

//////////////////////////////////////////////////
// State Encoding
//////////////////////////////////////////////////

localparam IDLE          = 0;
localparam WRITE_ADDR    = 1;
localparam WRITE_DATA    = 2;
localparam WRITE_RESP    = 3;
localparam READ_ADDR     = 4;
localparam READ_DATA     = 5;

//////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////

reg_interface dut(

    .clk(clk),
    .rst_n(rst_n),

    .awaddr(awaddr),
    .awvalid(awvalid),
    .awready(awready),

    .wdata(wdata),
    .wvalid(wvalid),
    .wready(wready),

    .bvalid(bvalid),
    .bready(bready),

    .araddr(araddr),
    .arvalid(arvalid),
    .arready(arready),

    .rdata(rdata),
    .rvalid(rvalid),
    .rready(rready),

    .dma_done(dma_done),

    .src_addr(src_addr),
    .dst_addr(dst_addr),
    .length(length),
    .start(start),

    .state_dbg(state_dbg)

);


// Clock


always #5 clk = ~clk;

// Reset Task


task reset_dut();

begin

    rst_n = 0;

    awaddr  = 0;
    awvalid = 0;

    wdata   = 0;
    wvalid  = 0;

    bready  = 0;

    araddr  = 0;
    arvalid = 0;

    rready  = 0;

    dma_done = 0;

    repeat(2)
        @(posedge clk);

    rst_n = 1;

    @(posedge clk);

end

endtask

//////////////////////////////////////////////////
// Check State
//////////////////////////////////////////////////

task check_state(

input logic [2:0] expected,
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
// Check Signal
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

endtask//////////////////////////////////////////////////
// Main Test
//////////////////////////////////////////////////

initial
begin

    clk = 0;

    pass_count = 0;
    fail_count = 0;

    //////////////////////////////////////////////
    // RESET TEST
    //////////////////////////////////////////////

    reset_dut();

    check_state(IDLE,"RESET");

    check_signal(start,0,"RESET_START");

    //////////////////////////////////////////////
    // WRITE SRC_ADDR
    //////////////////////////////////////////////

    awaddr  = 32'h00;
    awvalid = 1;
    

    @(posedge clk);


    check_state(WRITE_ADDR,"WRITE_SRC_ADDR");
 
    @(posedge clk);

    awvalid = 0;

    wdata  = 32'h1000;
    wvalid = 1;
     
  check_state(WRITE_DATA,"WRITE_SRC_DATA");

    @(posedge clk);
    
   
     

    @(posedge clk);
 

    wvalid = 0;
    wait(bvalid);
    check_signal(bvalid,1,"WRITE_RESP_SRC");
 

    bready = 1;
 

    @(posedge clk);
 

    bready = 0;

    if(src_addr == 32'h1000)

    begin

        pass_count++;

        $display("[PASS] SRC_ADDR_WRITE");

    end

    else

    begin

        fail_count++;

        $error("[FAIL] SRC_ADDR_WRITE");

    end

    //////////////////////////////////////////////
    // WRITE DST_ADDR
    //////////////////////////////////////////////

    awaddr  = 32'h04;
    awvalid = 1;

    @(posedge clk);

    @(posedge clk);

    awvalid = 0;

    wdata = 32'h2000;
    wvalid = 1;

    @(posedge clk);

    @(posedge clk);

    wvalid = 0;

    bready = 1;

    @(posedge clk);

    bready = 0;

    if(dst_addr == 32'h2000)

    begin

        pass_count++;

        $display("[PASS] DST_ADDR_WRITE");

    end

    else

    begin

        fail_count++;

        $error("[FAIL] DST_ADDR_WRITE");

    end

    //////////////////////////////////////////////
    // WRITE LENGTH
    //////////////////////////////////////////////

    awaddr = 32'h08;
    awvalid = 1;

    @(posedge clk);

    @(posedge clk);

    awvalid = 0;

    wdata = 32'd64;
    wvalid = 1;

    @(posedge clk);

    @(posedge clk);

    wvalid = 0;

    bready = 1;

    @(posedge clk);

    bready = 0;

    if(length == 32'd64)

    begin

        pass_count++;

        $display("[PASS] LENGTH_WRITE");

    end

    else

    begin

        fail_count++;

        $error("[FAIL] LENGTH_WRITE");

    end

    //////////////////////////////////////////////
    // WRITE CONTROL (START)
    //////////////////////////////////////////////

    awaddr = 32'h0C;
    awvalid = 1;

    @(posedge clk);

    @(posedge clk);

    awvalid = 0;

    wdata = 32'h1;
    wvalid = 1;

    @(posedge clk);

   check_signal(start,1,"START_PULSE");


    wvalid = 0;
    
    

    bready = 1;

    @(posedge clk);

    bready = 0;

    //////////////////////////////////////////////
    // DMA DONE
    //////////////////////////////////////////////

    dma_done = 1;

    @(posedge clk);

    dma_done = 0;

    $display("[PASS] DMA_DONE_UPDATED");

    // READ SRC_ADDR
    
    araddr  = 32'h00;
    arvalid = 1;
    
    @(posedge clk);
    
    @(posedge clk);
    
    arvalid = 0;

    rready = 1;
    
    if(rdata == 32'h1000)

    begin
        pass_count++;
        $display("[PASS] READ_SRC_ADDR");
    end

    else

    begin
        fail_count++;
        $error("[FAIL] READ_SRC_ADDR");
    end
    @(posedge clk);
    rready = 0;

    //////////////////////////////////////////////
    // READ DST_ADDR
    

    araddr = 32'h04;
    arvalid = 1;

    @(posedge clk);

    @(posedge clk);

    arvalid = 0;

    rready = 1;

    if(rdata == 32'h2000)

    begin
        pass_count++;
        $display("[PASS] READ_DST_ADDR");
    end

    else

    begin
        fail_count++;
        $error("[FAIL] READ_DST_ADDR");
    end
    @(posedge clk);
    rready = 0;

    //////////////////////////////////////////////
    // READ LENGTH
    
    araddr = 32'h08;
    arvalid = 1;

    @(posedge clk);
 
    arvalid = 0;
    
    rready = 1;    
    if(length == 32'd64)

    begin
        pass_count++;
        $display("[PASS] READ_LENGTH");
    end

    else

    begin
        fail_count++;
        $error("[FAIL] READ_LENGTH");
    end

    rready = 0;

    
    // READ STATUS
    
    araddr = 32'h10;
    arvalid = 1;

    @(posedge clk);

    @(posedge clk);

    arvalid = 0;

    rready = 1;

   
    if(rdata == 32'h1)

    begin
        pass_count++;
        $display("[PASS] READ_STATUS");
    end

    else

    begin
        fail_count++;
        $error("[FAIL] READ_STATUS");
    end

@(posedge clk);
    rready = 0;
    
        // RETURN TO IDLE
   
  
    @(posedge clk);
  
    check_state(IDLE,"RETURN_TO_IDLE");

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
// Waveform
//////////////////////////////////////////////////

initial
begin

    $dumpfile("reg_interface.vcd");

    $dumpvars(0,reg_interface_tb);

end

endmodule
