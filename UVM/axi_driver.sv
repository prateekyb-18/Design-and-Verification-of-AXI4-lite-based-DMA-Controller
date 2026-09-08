`include "uvm_pkg_import.svh"
class axi_driver extends uvm_driver #(axi_transaction);

    `uvm_component_utils(axi_driver)

    // Virtual interface
    virtual axi_dma_if vif;

    function new(string name = "axi_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi_dma_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF",
                       "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);

        axi_transaction tr;

        // Initialize signals
        vif.awvalid <= 0;
        vif.wvalid  <= 0;
        vif.bready  <= 0;
        vif.arvalid <= 0;
        vif.rready  <= 0;

        forever begin

            seq_item_port.get_next_item(tr);

            if (tr.write)
                drive_write(tr);
            else
                drive_read(tr);

            seq_item_port.item_done();

        end

    endtask


    //================================================
    // AXI4-Lite WRITE
    //================================================
    task drive_write(axi_transaction tr);

    // Write address
    @(posedge vif.clk);
    vif.awaddr  <= tr.addr;
    vif.awvalid <= 1'b1;

    do @(posedge vif.clk);
    while (!vif.awready);

    vif.awvalid <= 1'b0;


    // Write data
    vif.wdata  <= tr.data;
    vif.wvalid <= 1'b1;

    do @(posedge vif.clk);
    while (!vif.wready);

    vif.wvalid <= 1'b0;


    // Write response
    vif.bready <= 1'b1;

    do @(posedge vif.clk);
    while (!vif.bvalid);

    tr.bresp = vif.bresp;

    @(posedge vif.clk);
    vif.bready <= 1'b0;

endtask


    //================================================
    // AXI4-Lite READ
    //================================================
    task drive_read(axi_transaction tr);

    @(posedge vif.clk);

    vif.araddr  <= tr.addr;
    vif.arvalid <= 1'b1;

    do @(posedge vif.clk);
    while (!vif.arready);

    vif.arvalid <= 1'b0;


    // Read response
    vif.rready <= 1'b1;

    do @(posedge vif.clk);
    while (!vif.rvalid);

    tr.rdata = vif.rdata;
    tr.rresp = vif.rresp;

    @(posedge vif.clk);
    vif.rready <= 1'b0;

endtask

endclass
