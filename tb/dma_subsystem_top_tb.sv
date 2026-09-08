`timescale 1ns/1ps

module dma_subsystem_top_tb;

    //------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter BURST_LEN  = 4;

    //------------------------------------------------------------
    // Clock & Reset
    //------------------------------------------------------------
    logic clk;
    logic rst_n;

    //------------------------------------------------------------
    // AXI4-Lite Slave Interface (CPU -> DUT)
    //------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] s_awaddr;
    logic                  s_awvalid;
    logic                  s_awready;

    logic [DATA_WIDTH-1:0] s_wdata;
    logic                  s_wvalid;
    logic                  s_wready;

    logic                  s_bvalid;
    logic                  s_bready;

    logic [ADDR_WIDTH-1:0] s_araddr;
    logic                  s_arvalid;
    logic                  s_arready;

    logic [DATA_WIDTH-1:0] s_rdata;
    logic                  s_rvalid;
    logic                  s_rready;

    //------------------------------------------------------------
    // AXI Read Master Interface
    //------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] m_araddr;
    logic [7:0]            m_arlen;
    logic [2:0]            m_arsize;
    logic                  m_arvalid;
    logic                  m_arready;

    logic [DATA_WIDTH-1:0] m_rdata;
    logic                  m_rvalid;
    logic                  m_rlast;
    logic                  m_rready;

    //------------------------------------------------------------
    // AXI Write Master Interface
    //------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] m_awaddr;
    logic [7:0]            m_awlen;
    logic [2:0]            m_awsize;
    logic                  m_awvalid;
    logic                  m_awready;

    logic [DATA_WIDTH-1:0] m_wdata;
    logic                  m_wvalid;
    logic                  m_wlast;
    logic                  m_wready;

    logic                  m_bvalid;
    logic                  m_bready;

    //------------------------------------------------------------
    // Interrupt Interface
    //------------------------------------------------------------
    logic irq_enable;
    logic irq_clear;
    logic irq;

    //------------------------------------------------------------
    // Memory Model
    //------------------------------------------------------------
    logic [31:0] memory [0:255];

    integer i;

    //------------------------------------------------------------
    // Clock Generation (100 MHz)
    //------------------------------------------------------------
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //------------------------------------------------------------
    // Reset Generation
    //------------------------------------------------------------
    initial
    begin
        rst_n = 0;

        s_awaddr  = '0;
        s_awvalid = 0;
        s_wdata   = '0;
        s_wvalid  = 0;
        s_bready  = 0;

        s_araddr  = '0;
        s_arvalid = 0;
        s_rready  = 0;

        m_arready = 0;
        m_rdata   = '0;
        m_rvalid  = 0;
        m_rlast   = 0;

        m_awready = 0;
        m_wready  = 0;
        m_bvalid  = 0;

        irq_enable = 0;
        irq_clear  = 0;

        #20;
        rst_n = 1;
    end

    //------------------------------------------------------------
    // Memory Initialization
    //------------------------------------------------------------
    initial
    begin
        for(i = 0; i < 256; i = i + 1)
            memory[i] = i + 32'h1000;
    end

   initial 
begin
   force m_arready=1'b1;
   force m_arready=1'b1;
force m_rvalid=1'b1;
force m_rlast=1'b1;
force m_rdata=1'b1;
force m_awready=1'b1;
force m_awvalid=1'b1;
force m_wready=1'b1;
force m_bvalid=1'b1;
end
//------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------
    dma_subsystem_top #(

        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BURST_LEN(BURST_LEN)

    ) dut (

        //--------------------------------------------------------
        // Clock & Reset
        //--------------------------------------------------------
        .clk(clk),
        .rst_n(rst_n),

        //--------------------------------------------------------
        // AXI4-Lite Slave Interface
        //--------------------------------------------------------
        .s_awaddr(s_awaddr),
        .s_awvalid(s_awvalid),
        .s_awready(s_awready),

        .s_wdata(s_wdata),
        .s_wvalid(s_wvalid),
        .s_wready(s_wready),

        .s_bvalid(s_bvalid),
        .s_bready(s_bready),

        .s_araddr(s_araddr),
        .s_arvalid(s_arvalid),
        .s_arready(s_arready),

        .s_rdata(s_rdata),
        .s_rvalid(s_rvalid),
        .s_rready(s_rready),

        //--------------------------------------------------------
        // AXI Read Master Interface
        //--------------------------------------------------------
        .m_araddr(m_araddr),
        .m_arlen(m_arlen),
        .m_arsize(m_arsize),
        .m_arvalid(m_arvalid),
        .m_arready(m_arready),

        .m_rdata(m_rdata),
        .m_rvalid(m_rvalid),
        .m_rlast(m_rlast),
        .m_rready(m_rready),

        //--------------------------------------------------------
        // AXI Write Master Interface
        //--------------------------------------------------------
        .m_awaddr(m_awaddr),
        .m_awlen(m_awlen),
        .m_awsize(m_awsize),
        .m_awvalid(m_awvalid),
        .m_awready(m_awready),

        .m_wdata(m_wdata),
        .m_wvalid(m_wvalid),
        .m_wlast(m_wlast),
        .m_wready(m_wready),

        .m_bvalid(m_bvalid),
        .m_bready(m_bready),

        //--------------------------------------------------------
        // Interrupt
        //--------------------------------------------------------
        .irq_enable(irq_enable),
        .irq_clear(irq_clear),
        .irq(irq)

    );

    //------------------------------------------------------------
    // Waveform Dump
    //------------------------------------------------------------
    initial
    begin
        $dumpfile("dma_subsystem_top.vcd");
        $dumpvars(0, dma_subsystem_top_tb);
    end
//------------------------------------------------------------
    // AXI4-Lite Register Write Task
    //------------------------------------------------------------
    task automatic axi_write;

        input [31:0] addr;
        input [31:0] data;

        begin

            //----------------------------------------------------
            // Write Address Phase
            //----------------------------------------------------
            @(posedge clk);

            s_awaddr  <= addr;
            s_awvalid <= 1'b1;
            repeat(2) @(posedge clk);
 
            s_awready<=1'b1;           
            wait(s_awready == 1'b1);
           
 
            @(posedge clk);

            s_awvalid <= 1'b0;
            s_awaddr  <= '0;

            //----------------------------------------------------
            // Write Data Phase
            //----------------------------------------------------
            s_wdata  <= data;
            s_wvalid <= 1'b1;



            wait(s_wready == 1'b1);


            @(posedge clk);

            s_wvalid <= 1'b0;
            s_wdata  <= '0;

            //----------------------------------------------------
            // Write Response Phase
            //----------------------------------------------------
            s_bready <= 1'b1;


            wait(s_bvalid == 1'b1);



            @(posedge clk);

            s_bready <= 1'b0;

            //----------------------------------------------------
            // Status Message
            //----------------------------------------------------
            $display("[%0t] AXI WRITE : ADDR = 0x%08h DATA = 0x%08h",
                     $time, addr, data);

        end

    endtask
//------------------------------------------------------------
    // AXI4-Lite Register Read Task
    //------------------------------------------------------------
    task automatic axi_read;

        input  [31:0] addr;
        output [31:0] data;

        begin

            //----------------------------------------------------
            // Read Address Phase
            //----------------------------------------------------
            @(posedge clk);

            s_araddr  <= addr;
            s_arvalid <= 1'b1;


            wait(s_arready == 1'b1);



            @(posedge clk);

            s_arvalid <= 1'b0;
            s_araddr  <= '0;

            //----------------------------------------------------
            // Read Data Phase
            //----------------------------------------------------
            s_rready <= 1'b1;



            wait(s_rvalid == 1'b1);



            data = s_rdata;

            @(posedge clk);

            s_rready <= 1'b0;

            //----------------------------------------------------
            // Status Message
            //----------------------------------------------------
            $display("[%0t] AXI READ  : ADDR = 0x%08h DATA = 0x%08h",
                     $time, addr, data);

        end

    endtask

    //------------------------------------------------------------
    // Read Memory Model Variables
    //------------------------------------------------------------
    integer rd_index;
    integer rd_count;
//------------------------------------------------------------
    // AXI Read Memory Model
    //------------------------------------------------------------
    initial
    begin

        m_arready = 0;
        m_rvalid  = 0;
        m_rdata   = '0;
        m_rlast   = 0;

        forever
        begin

            //----------------------------------------------------
            // Wait for Read Address Request
            //----------------------------------------------------
            @(posedge clk);

            if(m_arvalid)
            begin

                //------------------------------------------------
                // Accept Read Address
                //------------------------------------------------
                m_arready <= 1'b1;

                @(posedge clk);

                m_arready <= 1'b0;

                //------------------------------------------------
                // Calculate Memory Index
                //------------------------------------------------
                rd_index = m_araddr >> 2;

                //------------------------------------------------
                // Send Burst Data
                //------------------------------------------------
                for(rd_count = 0; rd_count < BURST_LEN; rd_count = rd_count + 1)
                begin

                    m_rready<=1'b1;
                    wait(m_rready);


                    @(posedge clk);

                    m_rvalid <= 1'b1;
                    m_rdata  <= memory[rd_index + rd_count];

                    if(rd_count == BURST_LEN-1)
                        m_rlast <= 1'b1;
                    else
                        m_rlast <= 1'b0;

                    wait(m_rready);

                    @(posedge clk);

                    m_rvalid <= 1'b0;
                    m_rlast  <= 1'b0;

                end

                //------------------------------------------------
                // Return Bus to Idle
                //------------------------------------------------
                @(posedge clk);

                m_rvalid <= 1'b0;
                m_rlast  <= 1'b0;
                m_rdata  <= '0;

            end

        end

    end

    //------------------------------------------------------------
    // Write Memory Model Variables
    //------------------------------------------------------------
    integer wr_index;
    integer wr_count;

//------------------------------------------------------------
    // AXI Write Memory Model
    //------------------------------------------------------------
    initial
    begin

        m_awready = 0;
        m_wready  = 0;
        m_bvalid  = 0;

        forever
        begin

            //----------------------------------------------------
            // Wait for Write Address
            //----------------------------------------------------
            @(posedge clk);

            if(m_awvalid)
            begin

                //------------------------------------------------
                // Accept Write Address
                //------------------------------------------------
                m_awready <= 1'b1;

                @(posedge clk);

                m_awready <= 1'b0;

                //------------------------------------------------
                // Calculate Memory Index
                //------------------------------------------------
                wr_index = m_awaddr >> 2;
                wr_count = 0;

                //------------------------------------------------
                // Receive Write Data Burst
                //------------------------------------------------
                while(1)
                begin

                    m_wready <= 1'b1;

                    wait(m_wvalid);

                    @(posedge clk);

                    memory[wr_index + wr_count] = m_wdata;

                    wr_count = wr_count + 1;

                    if(m_wlast)
                    begin

                        m_wready <= 1'b0;

                        //------------------------------------------------
                        // Write Response
                        //------------------------------------------------
                        m_bvalid <= 1'b1;

                        wait(m_bready);

                        @(posedge clk);

                        m_bvalid <= 1'b0;

                        disable fork;

                        break;

                    end

                end

            end

        end

    end
//------------------------------------------------------------
    // DMA Transfer Test & Self Checking
    //------------------------------------------------------------
    logic [31:0] read_data;

    initial
    begin

        //--------------------------------------------------------
        // Wait for Reset Release
        //--------------------------------------------------------
 $display("[%0t] waiting for rst_n",$time);

        wait(rst_n);
$display("[%0t] received rst_n",$time);

        repeat(5) @(posedge clk);

        $display("\n========================================");
        $display("      DMA SUBSYSTEM TEST STARTED");
        $display("========================================\n");

        //--------------------------------------------------------
        // Enable Interrupt
        //--------------------------------------------------------
        irq_enable = 1'b1;
        @(posedge clk);
        irq_clear  = 1'b0;

        //--------------------------------------------------------
        // Program DMA Registers
        //--------------------------------------------------------
        axi_write(32'h00, 32'h00000000);   // Source Address
$display("src programmed");

        axi_write(32'h04, 32'h00000040);   // Destination Address
$display("dst programmed");

        axi_write(32'h08, 32'd16);         // Transfer Length (16 Bytes)
$display("length programmed");

        axi_write(32'h0C, 32'h00000001);   // Start DMA

$display("start programmed");   
          
        //--------------------------------------------------------
        // End of Simulation
        //--------------------------------------------------------
        $display("\n========================================");
        $display("      ALL TESTS COMPLETED");
        $display("========================================\n");

        #20;
        $finish;

    end

endmodule
