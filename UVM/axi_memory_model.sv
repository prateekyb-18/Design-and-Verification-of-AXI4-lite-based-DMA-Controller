`include "uvm_pkg_import.svh"
class axi_memory_model extends uvm_component;

    `uvm_component_utils(axi_memory_model)

    virtual axi_dma_if vif;

    logic [31:0] memory [0:4095];

    function new(string name = "axi_memory_model",
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

        forever begin

            @(posedge vif.clk);

            //------------------------------------------------
            // AXI READ ADDRESS
            //------------------------------------------------
            if (vif.m_arvalid) begin

                vif.m_arready <= 1'b1;

                @(posedge vif.clk);

                vif.m_arready <= 1'b0;

                //------------------------------------------------
                // Send burst data
                //------------------------------------------------
                for (int i = 0; i < 4; i++) begin

                    vif.m_rdata  <= memory[
                        (vif.m_araddr >> 2) + i
                    ];

                    vif.m_rvalid <= 1'b1;
                    vif.m_rlast  <= (i == 3);

                    do @(posedge vif.clk);
                    while (!vif.m_rready);

                    vif.m_rvalid <= 1'b0;
                    vif.m_rlast  <= 1'b0;

                end

            end


            //------------------------------------------------
            // AXI WRITE ADDRESS
            //------------------------------------------------
            if (vif.m_awvalid) begin

                vif.m_awready <= 1'b1;

                @(posedge vif.clk);

                vif.m_awready <= 1'b0;

            end


            //------------------------------------------------
            // AXI WRITE DATA
            //------------------------------------------------
            if (vif.m_wvalid) begin

                vif.m_wready <= 1'b1;

                if (vif.m_wready) begin

                    memory[0] = vif.m_wdata;

                end

                @(posedge vif.clk);

                vif.m_wready <= 1'b0;

                if (vif.m_wlast) begin

                    vif.m_bvalid <= 1'b1;

                    do @(posedge vif.clk);
                    while (!vif.m_bready);

                    vif.m_bvalid <= 1'b0;

                end

            end

        end

    endtask

endclass
