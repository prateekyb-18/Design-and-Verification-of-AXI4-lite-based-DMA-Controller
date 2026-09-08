`timescale 1ns/1ps

module dma_subsystem_top #(

    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BURST_LEN  = 4

)(

    //------------------------------------------------------------
    // Clock & Reset
    //------------------------------------------------------------
    input  logic clk,
    input  logic rst_n,

    //------------------------------------------------------------
    // AXI4-Lite Slave Interface (CPU)
    //------------------------------------------------------------
    input  logic [ADDR_WIDTH-1:0] s_awaddr,
    input  logic                  s_awvalid,
    output logic                  s_awready,

    input  logic [DATA_WIDTH-1:0] s_wdata,
    input  logic                  s_wvalid,
    output logic                  s_wready,

    output logic                  s_bvalid,
    input  logic                  s_bready,

    input  logic [ADDR_WIDTH-1:0] s_araddr,
    input  logic                  s_arvalid,
    output logic                  s_arready,

    output logic [DATA_WIDTH-1:0] s_rdata,
    output logic                  s_rvalid,
    input  logic                  s_rready,

    //------------------------------------------------------------
    // AXI Read Master Interface
    //------------------------------------------------------------
    output logic [ADDR_WIDTH-1:0] m_araddr,
    output logic [7:0]            m_arlen,
    output logic [2:0]            m_arsize,
    output logic                  m_arvalid,
    input  logic                  m_arready,

    input  logic [DATA_WIDTH-1:0] m_rdata,
    input  logic                  m_rvalid,
    input  logic                  m_rlast,
    output logic                  m_rready,

    //------------------------------------------------------------
    // AXI Write Master Interface
    //------------------------------------------------------------
    output logic [ADDR_WIDTH-1:0] m_awaddr,
    output logic [7:0]            m_awlen,
    output logic [2:0]            m_awsize,
    output logic                  m_awvalid,
    input  logic                  m_awready,

    output logic [DATA_WIDTH-1:0] m_wdata,
    output logic                  m_wvalid,
    output logic                  m_wlast,
    input  logic                  m_wready,

    input  logic                  m_bvalid,
    output logic                  m_bready,

    //------------------------------------------------------------
    // Interrupt
    //------------------------------------------------------------
    input  logic irq_enable,
    input  logic irq_clear,
    output logic irq

);

    //------------------------------------------------------------
    // Internal Signals
    //------------------------------------------------------------

    logic [31:0] src_addr;
    logic [31:0] dst_addr;
    logic [31:0] length;

    logic [31:0] current_src_addr;
    logic [31:0] current_dst_addr;
    logic [31:0] remaining_length;

    logic transfer_done;

    logic load_config;
    logic read_start;
    logic write_start;
    logic update_addr;
    logic dma_done;

    logic read_done;
    logic write_done;

    logic fifo_full;
    logic fifo_empty;

    logic fifo_wr_en;
    logic fifo_rd_en;

    logic [31:0] fifo_wr_data;
    logic [31:0] fifo_rd_data;

    logic [31:0] burst_bytes;

    logic [2:0] reg_state_dbg;
    logic [3:0] cfsm_state_dbg;
    logic [1:0] read_state_dbg;
    logic [2:0] write_state_dbg;

    //------------------------------------------------------------
    // Burst Size
    //------------------------------------------------------------

    assign burst_bytes = 32'd16;

    //------------------------------------------------------------
    // Register Interface
    //------------------------------------------------------------

    reg_interface #(

        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)

    ) u_reg_interface (

        .clk(clk),
        .rst_n(rst_n),

        .awaddr(s_awaddr),
        .awvalid(s_awvalid),
        .awready(s_awready),

        .wdata(s_wdata),
        .wvalid(s_wvalid),
        .wready(s_wready),

        .bvalid(s_bvalid),
        .bready(s_bready),

        .araddr(s_araddr),
        .arvalid(s_arvalid),
        .arready(s_arready),

        .rdata(s_rdata),
        .rvalid(s_rvalid),
        .rready(s_rready),

        .dma_done(dma_done),

        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .length(length),
        .start(start),

        .state_dbg(reg_state_dbg)

    );

    //------------------------------------------------------------
    // Address Generator
    //------------------------------------------------------------

    add_gen u_add_gen (

        .clk(clk),
        .rst(rst_n),

        .src_addr_in(src_addr),
        .dst_addr_in(dst_addr),
        .length_in(length),

        .update_addr(update_addr),

        .transfer_done(transfer_done),
        .remaining_length(remaining_length),

        .burst_bytes(burst_bytes),

        .load_config(load_config),

        .current_src_addr(current_src_addr),
        .current_dst_addr(current_dst_addr)

    );

//------------------------------------------------------------
    // Internal Start Signal
    //------------------------------------------------------------

    logic start;

    //------------------------------------------------------------
    // Control FSM
    //------------------------------------------------------------

    cfsm u_cfsm (

        .clk(clk),
        .rst_n(rst_n),

        .start(start),

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

        .state_dbg(cfsm_state_dbg)

    );

    //------------------------------------------------------------
    // Read Master
    //------------------------------------------------------------

    read_master #(

        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BURST_LEN(BURST_LEN)

    ) u_read_master (

        .clk(clk),
        .rst(rst_n),

        .read_start(read_start),

        .src_addr(current_src_addr),

        .fifo_full(fifo_full),
        .fifo_wr_en(fifo_wr_en),
        .fifo_wr_data(fifo_wr_data),

        .araddr(m_araddr),
        .arlen(m_arlen),
        .arsize(m_arsize),
        .arvalid(m_arvalid),
        .arready(m_arready),

        .rdata(m_rdata),
        .rvalid(m_rvalid),
        .rlast(m_rlast),
        .rready(m_rready),

        .read_done(read_done),

        .state_dbg(read_state_dbg)

    );

    //------------------------------------------------------------
    // FIFO
    //------------------------------------------------------------

    fifo #(

        .data_width(DATA_WIDTH),
        .depth(16)

    ) u_fifo (

        .clk(clk),

        .rst(~rst_n),

        .wrt_en(fifo_wr_en),
        .rd_en(fifo_rd_en),

        .wrt_data(fifo_wr_data),
        .rd_data(fifo_rd_data),

        .full(fifo_full),
        .empty(fifo_empty)

    );

    //------------------------------------------------------------
    // Write Master
    //------------------------------------------------------------

    write_master #(

        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BURST_LEN(BURST_LEN)

    ) u_write_master (

        .clk(clk),
        .rst_n(rst_n),

        .write_start(write_start),

        .dst_addr(current_dst_addr),

        .fifo_empty(fifo_empty),
        .fifo_rd_data(fifo_rd_data),
        .fifo_rd_en(fifo_rd_en),

        .awaddr(m_awaddr),
        .awlen(m_awlen),
        .awsize(m_awsize),
        .awvalid(m_awvalid),
        .awready(m_awready),

        .wdata(m_wdata),
        .wvalid(m_wvalid),
        .wlast(m_wlast),
        .wready(m_wready),

        .bvalid(m_bvalid),
        .bready(m_bready),

        .write_done(write_done),

        .state_dbg(write_state_dbg)

    );

//------------------------------------------------------------
    // Interrupt Controller
    //------------------------------------------------------------

    interrupt u_interrupt (

        .clk(clk),
        .rst_n(rst_n),

        .dma_done(dma_done),

        .irq_enable(irq_enable),
        .irq_clear(irq_clear),

        .irq(irq)

    );

endmodule
