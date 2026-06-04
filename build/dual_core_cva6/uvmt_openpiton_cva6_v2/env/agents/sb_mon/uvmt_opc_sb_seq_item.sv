// ============================================================================
// uvmt_opc_sb_seq_item.sv
// Item de sequencia para commits do store buffer.
// Capturado pelo uvmt_opc_sb_mon_c ao detectar sb{N}_commit na interface.
// ============================================================================
`ifndef __UVMT_OPC_SB_SEQ_ITEM_SV__
`define __UVMT_OPC_SB_SEQ_ITEM_SV__

class uvmt_opc_sb_seq_item_c extends uvm_sequence_item;

    `uvm_object_utils_begin(uvmt_opc_sb_seq_item_c)
        `uvm_field_int(tile_id,     UVM_ALL_ON)
        `uvm_field_int(address,     UVM_ALL_ON)
        `uvm_field_int(data,        UVM_ALL_ON)
        `uvm_field_int(cycle_count, UVM_ALL_ON)
    `uvm_object_utils_end

    int unsigned     tile_id;      // 0 ou 1
    logic [55:0]     address;      // endereço físico do store
    logic [63:0]     data;         // dado escrito
    longint unsigned cycle_count;  // ciclo do commit

    function new(string name = "uvmt_opc_sb_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("SB_COMMIT tile=%0d addr=0x%014h data=0x%016h @cyc=%0d",
                         tile_id, address, data, cycle_count);
    endfunction

endclass : uvmt_opc_sb_seq_item_c

`endif // __UVMT_OPC_SB_SEQ_ITEM_SV__
