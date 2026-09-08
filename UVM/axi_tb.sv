`timescale 1ns/1ps
`include "uvm_pkg_import.svh"
module axi_tb;

    //------------------------------------------------
    // Clock and Reset
    //------------------------------------------------
    logic clk;
    logic rst_n;

    //------------------------------------------------
    // IRQ
    //------------------------------------------------
    logic irq_enable;
    logic irq_clear;
    logic irq;

    //------------------------------------------------
    // AXI Interface
    //------------------------------------------------
    axi_dma_if axi_if (
        .clk  (clk),
        .rst_n(rst_n)
    );

    //------------------------------------------------
    // DUT
    //------------------------------------------------
    dma_subsystem_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .BURST_LEN (4)
    ) dut (

        .clk   (clk),
        .rst_n (rst_n),

        //------------------------------------------------
        // AXI4-Lite Slave
        //------------------------------------------------
        .s_awaddr  (axi_if.awaddr),
        .s_awvalid (axi_if.awvalid),
        .s_awready (axi_if.awready),

        .s_wdata   (axi_if.wdata),
        .s_wvalid  (axi_if.wvalid),
        .s_wready  (axi_if.wready),

        .s_bvalid  (axi_if.bvalid),
        .s_bready  (axi_if.bready),

        .s_araddr  (axi_if.araddr),
        .s_arvalid (axi_if.arvalid),
        .s_arready (axi_if.arready),

        .s_rdata   (axi_if.rdata),
        .s_rvalid  (axi_if.rvalid),
        .s_rready  (axi_if.rready),

        //------------------------------------------------
        // AXI Read Master
        //------------------------------------------------
        .m_araddr  (axi_if.m_araddr),
        .m_arlen   (axi_if.m_arlen),
        .m_arsize  (axi_if.m_arsize),
        .m_arvalid (axi_if.m_arvalid),
        .m_arready (axi_if.m_arready),

        .m_rdata   (axi_if.m_rdata),
        .m_rvalid  (axi_if.m_rvalid),
        .m_rlast   (axi_if.m_rlast),
        .m_rready  (axi_if.m_rready),

        //------------------------------------------------
        // AXI Write Master
        //------------------------------------------------
        .m_awaddr  (axi_if.m_awaddr),
        .m_awlen   (axi_if.m_awlen),
        .m_awsize  (axi_if.m_awsize),
        .m_awvalid (axi_if.m_awvalid),
        .m_awready (axi_if.m_awready),

        .m_wdata   (axi_if.m_wdata),
        .m_wvalid  (axi_if.m_wvalid),
        .m_wlast   (axi_if.m_wlast),
        .m_wready  (axi_if.m_wready),

        .m_bvalid  (axi_if.m_bvalid),
        .m_bready  (axi_if.m_bready),

        //------------------------------------------------
        // Interrupt
        //------------------------------------------------
        .irq_enable(irq_enable),
        .irq_clear (irq_clear),
        .irq       (irq)

    );

    //------------------------------------------------
    // Clock
    //------------------------------------------------
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    //------------------------------------------------
    // Reset
    //------------------------------------------------
    initial begin

        rst_n      = 1'b0;
        irq_enable = 1'b1;
        irq_clear  = 1'b0;

        // AXI master-side defaults
        axi_if.m_arready = 1'b0;
        axi_if.m_rdata   = '0;
        axi_if.m_rvalid  = 1'b0;
        axi_if.m_rlast   = 1'b0;

        axi_if.m_awready = 1'b0;
        axi_if.m_wready  = 1'b0;
        axi_if.m_bvalid  = 1'b0;

        #100;

        rst_n = 1'b1;

    end

    //------------------------------------------------
    // UVM Configuration
    //------------------------------------------------
    initial begin

        uvm_config_db#(virtual axi_dma_if)::set(
            null,
            "*",
            "vif",
            axi_if
        );

        run_test("axi_test");

    end

endmodule
