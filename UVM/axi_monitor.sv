`include "uvm_pkg_import.svh"
class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    virtual axi_dma_if vif;

    uvm_analysis_port #(axi_transaction) analysis_port;

    function new(string name = "axi_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
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

    forever begin

        @(posedge vif.clk);

        //================================================
        // Monitor WRITE transaction
        //================================================
        if (vif.awvalid && vif.awready) begin

            axi_transaction tr;

            tr = axi_transaction::type_id::create("tr");

            tr.write = 1;
            tr.addr  = vif.awaddr;

            // Wait for write data handshake
            do @(posedge vif.clk);
            while (!(vif.wvalid && vif.wready));

            tr.data = vif.wdata;

            // Wait for write response
            do @(posedge vif.clk);
            while (!(vif.bvalid && vif.bready));

            tr.bresp = vif.bresp;

            analysis_port.write(tr);

            `uvm_info("AXI_MON",
                      $sformatf(
                      "WRITE ADDR=0x%08h DATA=0x%08h",
                      tr.addr,
                      tr.data),
                      UVM_MEDIUM)
        end


        //================================================
        // Monitor READ transaction
        //================================================
        if (vif.arvalid && vif.arready) begin

            axi_transaction tr;

            tr = axi_transaction::type_id::create("tr");

            tr.write = 0;
            tr.addr  = vif.araddr;

            // Wait for read response
            do @(posedge vif.clk);
            while (!(vif.rvalid && vif.rready));

            tr.rdata = vif.rdata;
            tr.rresp = vif.rresp;

            analysis_port.write(tr);

            `uvm_info("AXI_MON",
                      $sformatf(
                      "READ ADDR=0x%08h DATA=0x%08h",
                      tr.addr,
                      tr.rdata),
                      UVM_MEDIUM)
        end

    end

endtask

             

endclass
