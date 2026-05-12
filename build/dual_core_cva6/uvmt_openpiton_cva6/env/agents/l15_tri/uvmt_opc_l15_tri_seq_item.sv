// ============================================================================
// uvmt_opc_l15_tri_seq_item.sv
// ============================================================================
`ifndef __UVMT_OPC_L15_TRI_SEQ_ITEM_SV__
`define __UVMT_OPC_L15_TRI_SEQ_ITEM_SV__

// Tipos de requisicao (de l15.h do OpenPiton)
typedef enum logic [3:0] {
    L15_REQ_LOAD  = 4'h0,
    L15_REQ_STORE = 4'h1,
    L15_REQ_IFILL = 4'h8,
    L15_REQ_AMO   = 4'hC,
    L15_REQ_FLUSH = 4'hE
} opc_l15_req_type_e;

// Tipos de retorno
typedef enum logic [3:0] {
    L15_RET_LOAD   = 4'h0,
    L15_RET_ST_ACK = 4'h3,
    L15_RET_IFILL  = 4'h4,
    L15_RET_AMO    = 4'h7,
    L15_RET_INVAL  = 4'h8  // invalidacao sincrona retornada como resposta
} opc_l15_ret_type_e;

class uvmt_opc_l15_tri_seq_item_c extends uvm_sequence_item;

    `uvm_object_utils_begin(uvmt_opc_l15_tri_seq_item_c)
        `uvm_field_enum(opc_l15_req_type_e, req_type,     UVM_ALL_ON)
        `uvm_field_enum(opc_l15_ret_type_e, ret_type,     UVM_ALL_ON)
        `uvm_field_int(address,             UVM_ALL_ON)
        `uvm_field_int(req_data,            UVM_ALL_ON)
        `uvm_field_int(ret_data_0,          UVM_ALL_ON)
        `uvm_field_int(ret_data_1,          UVM_ALL_ON)
        `uvm_field_int(is_nc,               UVM_ALL_ON)
        `uvm_field_int(amo_op,              UVM_ALL_ON)
        `uvm_field_int(req_time_ps,         UVM_ALL_ON)
        `uvm_field_int(ret_time_ps,         UVM_ALL_ON)
        `uvm_field_int(is_inval,            UVM_ALL_ON)
        `uvm_field_int(inval_address,       UVM_ALL_ON)
    `uvm_object_utils_end

    opc_l15_req_type_e  req_type;
    opc_l15_ret_type_e  ret_type;

    logic [39:0]  address;
    logic [63:0]  req_data;
    logic [63:0]  ret_data_0;
    logic [63:0]  ret_data_1;

    bit           is_nc;          // non-cacheable
    logic [3:0]   amo_op;

    longint unsigned req_time_ps;  // tempo da requisicao
    longint unsigned ret_time_ps;  // tempo da resposta

    // Invalidacao assincrona (canal separado)
    bit           is_inval;
    logic [39:0]  inval_address;

    function new(string name = "uvmt_opc_l15_tri_seq_item");
        super.new(name);
    endfunction

    // Latencia entre requisicao e resposta
    function int unsigned latency_ps();
        return int'(ret_time_ps - req_time_ps);
    endfunction

    function string convert2string();
        if (is_inval)
            return $sformatf("[L15 INVAL] addr=0x%010h t=%0t", inval_address, req_time_ps);
        else
            return $sformatf("[L15] %s addr=0x%010h req=0x%016h ret=%s data=0x%016h lat=%0d ps",
                req_type.name(), address, req_data, ret_type.name(), ret_data_0, latency_ps());
    endfunction

endclass : uvmt_opc_l15_tri_seq_item_c

`endif // __UVMT_OPC_L15_TRI_SEQ_ITEM_SV__
