// ============================================================================
// uvmt_opc_uart_seq_item.sv
// Sequence item para a UART virtual.
// ============================================================================
`ifndef __UVMT_OPC_UART_SEQ_ITEM_SV__
`define __UVMT_OPC_UART_SEQ_ITEM_SV__

class uvmt_opc_uart_seq_item_c extends uvm_sequence_item;

    `uvm_object_utils_begin(uvmt_opc_uart_seq_item_c)
        `uvm_field_int(data,  UVM_ALL_ON)
        `uvm_field_int(cycle, UVM_ALL_ON)
    `uvm_object_utils_end

    logic [7:0]    data;   // byte ASCII
    longint unsigned cycle;

    function new(string name = "uvmt_opc_uart_seq_item");
        super.new(name);
    endfunction

endclass : uvmt_opc_uart_seq_item_c

`endif // __UVMT_OPC_UART_SEQ_ITEM_SV__
