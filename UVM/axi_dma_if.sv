interface axi_dma_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst_n
);

    //========================================
    // AXI4-Lite Write Address Channel
    //========================================
    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;

    //========================================
    // AXI4-Lite Write Data Channel
    //========================================
    logic [DATA_WIDTH-1:0] wdata;
    logic                  wvalid;
    logic                  wready;

    //========================================
    // AXI4-Lite Write Response Channel
    //========================================
    logic                  bvalid;
    logic [1:0]            bresp;
    logic                  bready;

    //========================================
    // AXI4-Lite Read Address Channel
    //========================================
    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;

    //========================================
    // AXI4-Lite Read Data Channel
    //========================================
    logic [DATA_WIDTH-1:0] rdata;
    logic                  rvalid;
    logic [1:0]            rresp;
    logic                  rready;

    //========================================
    // DMA Status
    //========================================
    logic dma_done;
    logic irq;

    //========================================
    // AXI Read Master Interface
    //========================================
    logic [ADDR_WIDTH-1:0] m_araddr;
    logic [7:0]            m_arlen;
    logic [2:0]            m_arsize;
    logic                  m_arvalid;
    logic                  m_arready;

    logic [DATA_WIDTH-1:0] m_rdata;
    logic                  m_rvalid;
    logic                  m_rlast;
    logic                  m_rready;

    //========================================
    // AXI Write Master Interface
    //========================================
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

endinterface
