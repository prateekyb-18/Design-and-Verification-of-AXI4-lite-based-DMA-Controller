`include "uvm_pkg_import.svh"
class axi_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_transaction, axi_scoreboard) analysis_export;

    function new(string name = "axi_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        analysis_export = new("analysis_export", this);

    endfunction

    function void write(axi_transaction tr);

        if (tr.write) begin

            `uvm_info("SCOREBOARD",
                      $sformatf(
                      "WRITE: ADDR=0x%08h DATA=0x%08h BRESP=%0d",
                      tr.addr,
                      tr.data,
                      tr.bresp),
                      UVM_MEDIUM)

        end
        else begin

            `uvm_info("SCOREBOARD",
                      $sformatf(
                      "READ: ADDR=0x%08h DATA=0x%08h RRESP=%0d",
                      tr.addr,
                      tr.rdata,
                      tr.rresp),
                      UVM_MEDIUM)

        end

    endfunction

endclass
