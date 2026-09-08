`include "uvm_pkg_import.svh"
class axi_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_sequence)

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction

    task body();

        axi_transaction tr;

        //========================================
        // Write Source Address
        // Address = 0x00
        //========================================
        tr = axi_transaction::type_id::create("tr");

        start_item(tr);
        tr.write = 1;
        tr.addr  = 32'h0000_0000;
        tr.data  = 32'h0000_1000;
        finish_item(tr);


        //========================================
        // Write Destination Address
        // Address = 0x04
        //========================================
        tr = axi_transaction::type_id::create("tr");

        start_item(tr);
        tr.write = 1;
        tr.addr  = 32'h0000_0004;
        tr.data  = 32'h0000_2000;
        finish_item(tr);


        //========================================
        // Write Transfer Length
        // Address = 0x08
        //========================================
        tr = axi_transaction::type_id::create("tr");

        start_item(tr);
        tr.write = 1;
        tr.addr  = 32'h0000_0008;
        tr.data  = 32'h0000_0010;
        finish_item(tr);


        //========================================
        // Start DMA
        // Address = 0x0C
        //========================================
        tr = axi_transaction::type_id::create("tr");

        start_item(tr);
        tr.write = 1;
        tr.addr  = 32'h0000_000C;
        tr.data  = 32'h0000_0001;
        finish_item(tr);


        `uvm_info("AXI_SEQ",
                  "DMA configuration and START completed",
                  UVM_MEDIUM)

    endtask

endclass
