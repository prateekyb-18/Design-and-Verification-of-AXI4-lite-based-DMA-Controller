`include "uvm_pkg_import.svh"
class axi_env extends uvm_env;

    `uvm_component_utils(axi_env)

    axi_agent         agent;
    axi_scoreboard    scoreboard;
    axi_memory_model  memory_model;

    function new(string name = "axi_env",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agent = axi_agent::type_id::create(
                "agent", this);

        scoreboard = axi_scoreboard::type_id::create(
                     "scoreboard", this);

        memory_model = axi_memory_model::type_id::create(
                       "memory_model", this);

    endfunction

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        agent.monitor.analysis_port.connect(
            scoreboard.analysis_export
        );

    endfunction

endclass
