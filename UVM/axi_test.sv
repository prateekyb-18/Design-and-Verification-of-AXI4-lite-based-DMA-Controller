`include "uvm_pkg_import.svh"
class axi_test extends uvm_test;

    `uvm_component_utils(axi_test)

    axi_env      env;
    axi_sequence seq;

    function new(string name = "axi_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = axi_env::type_id::create("env", this);

    endfunction

    task run_phase(uvm_phase phase);

        phase.raise_objection(this);

        seq = axi_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        // Allow DMA to complete
        #1000ns;

        phase.drop_objection(this);

    endtask

endclass
