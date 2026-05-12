// ============================================================================
// uvmt_opc_noc_seq_item.sv
// Representa um pacote completo em qualquer das tres redes NoC do P-Mesh.
// ============================================================================
`ifndef __UVMT_OPC_NOC_SEQ_ITEM_SV__
`define __UVMT_OPC_NOC_SEQ_ITEM_SV__

// Tipos de mensagem conforme l15.h / noc_msg_type.vh do OpenPiton
typedef enum logic [7:0] {
    NOC_MSG_LOAD_REQ   = 8'h31,
    NOC_MSG_STORE_REQ  = 8'h33,
    NOC_MSG_IFILL_REQ  = 8'h34,
    NOC_MSG_AMO_REQ    = 8'h36,
    NOC_MSG_LOAD_RET   = 8'h21,
    NOC_MSG_ST_ACK     = 8'h22,
    NOC_MSG_IFILL_RET  = 8'h24,
    NOC_MSG_AMO_RET    = 8'h27,
    NOC_MSG_INVAL_REQ  = 8'h38,  // Home -> Requester: invalida linha
    NOC_MSG_INVAL_ACK  = 8'h28,  // Requester -> Home: confirmacao
    NOC_MSG_UNKNOWN    = 8'hFF
} opc_noc_msg_type_e;

// Rede de origem
typedef enum logic [1:0] {
    NOC_NETWORK_1 = 2'd0,   // Requisicoes
    NOC_NETWORK_2 = 2'd1,   // Respostas
    NOC_NETWORK_3 = 2'd2    // Forwarding / Invalidacoes
} opc_noc_network_e;

class uvmt_opc_noc_seq_item_c extends uvm_sequence_item;

    `uvm_object_utils_begin(uvmt_opc_noc_seq_item_c)
        `uvm_field_enum(opc_noc_network_e,  network,      UVM_ALL_ON)
        `uvm_field_enum(opc_noc_msg_type_e, msg_type,     UVM_ALL_ON)
        `uvm_field_int(src_x,               UVM_ALL_ON)
        `uvm_field_int(src_y,               UVM_ALL_ON)
        `uvm_field_int(dst_x,               UVM_ALL_ON)
        `uvm_field_int(dst_y,               UVM_ALL_ON)
        `uvm_field_int(address,             UVM_ALL_ON)
        `uvm_field_int(data,                UVM_ALL_ON)
        `uvm_field_int(mshrid,              UVM_ALL_ON)
        `uvm_field_int(pkt_len,             UVM_ALL_ON)
        `uvm_field_int(timestamp_ps,        UVM_ALL_ON)
        `uvm_field_int(is_coherence_msg,    UVM_ALL_ON)
    `uvm_object_utils_end

    opc_noc_network_e   network;
    opc_noc_msg_type_e  msg_type;

    logic [7:0]  src_x, src_y;      // coordenadas fonte
    logic [7:0]  dst_x, dst_y;      // coordenadas destino

    logic [39:0] address;            // endereco fisico (40 bits)
    logic [63:0] data;               // dado (primeiro word de payload)

    logic [9:0]  mshrid;             // Miss Status Holding Register ID
    int unsigned pkt_len;            // numero total de flits

    longint unsigned timestamp_ps;   // tempo de captura em ps
    bit is_coherence_msg;            // mensagem de protocolo de coerencia?

    function new(string name = "uvmt_opc_noc_seq_item");
        super.new(name);
    endfunction

    // Decodifica o header flit do P-Mesh (formato OpenPiton)
    // [7:0]   = msg_type
    // [15:8]  = pkt_len
    // [21:16] = reserved
    // [31:22] = mshrid
    // [39:32] = fbits
    // [47:40] = dst_x
    // [55:48] = dst_y
    // [63:56] = chip_id destino
    function void decode_header_flit(input logic [63:0] flit);
        msg_type = opc_noc_msg_type_e'(flit[7:0]);
        pkt_len  = int'(flit[15:8]);
        mshrid   = flit[31:22];
        dst_x    = flit[47:40];
        dst_y    = flit[55:48];
        is_coherence_msg = (msg_type == NOC_MSG_INVAL_REQ ||
                            msg_type == NOC_MSG_INVAL_ACK);
    endfunction

    // Decodifica o endereco do segundo flit (payload[0])
    // Formato varia por msg_type; simplificacao: addr nos bits [39:0]
    function void decode_addr_flit(input logic [63:0] flit);
        address = flit[39:0];
    endfunction

    function string convert2string();
        return $sformatf(
            "[NoC%0d] %s src=(%0d,%0d) dst=(%0d,%0d) addr=0x%010h data=0x%016h t=%0t",
            int'(network)+1, msg_type.name(),
            src_x, src_y, dst_x, dst_y,
            address, data, realtime'(timestamp_ps) * 1ps);
    endfunction

endclass : uvmt_opc_noc_seq_item_c

`endif // __UVMT_OPC_NOC_SEQ_ITEM_SV__
