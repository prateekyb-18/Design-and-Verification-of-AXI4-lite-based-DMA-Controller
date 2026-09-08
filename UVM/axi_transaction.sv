`include "uvm_pkg_import.svh"
class axi_transaction extends uvm_sequence_item;

    // AXI transaction type
    rand bit                  write;
    rand bit [31:0]           addr;
    rand bit [31:0]           data;

    // Read response data
    bit [31:0]                rdata;

    // AXI response
    bit [1:0]                 bresp;
    bit [1:0]                 rresp;

    // UVM factory registration
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(addr,  UVM_ALL_ON)
        `uvm_field_int(data,  UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(bresp, UVM_ALL_ON)
        `uvm_field_int(rresp, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

endclass
