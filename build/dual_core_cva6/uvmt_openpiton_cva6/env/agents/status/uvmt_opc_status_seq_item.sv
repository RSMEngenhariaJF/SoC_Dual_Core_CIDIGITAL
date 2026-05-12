// ============================================================================
// uvmt_opc_status_seq_item.sv
// ============================================================================
`ifndef __UVMT_OPC_STATUS_SEQ_ITEM_SV__
`define __UVMT_OPC_STATUS_SEQ_ITEM_SV__

typedef enum logic [1:0] {
    OPC_EV_GOOD_TRAP  = 2'd0,
    OPC_EV_BAD_TRAP   = 2'd1,
    OPC_EV_UART_CHAR  = 2'd2
} opc_status_event_e;

class uvmt_opc_status_seq_item_c extends uvm_sequence_item;

    `uvm_object_utils_begin(uvmt_opc_status_seq_item_c)
        `uvm_field_enum(opc_status_event_e, event_type, UVM_ALL_ON)
        `uvm_field_int(tile_id,    UVM_ALL_ON)
        `uvm_field_int(error_code, UVM_ALL_ON)
        `uvm_field_int(uart_char,  UVM_ALL_ON)
        `uvm_field_int(cycle,      UVM_ALL_ON)
    `uvm_object_utils_end

    opc_status_event_e event_type;
    int unsigned       tile_id;
    logic [63:0]       error_code;   // codigo de erro do bad_trap
    logic [7:0]        uart_char;    // caracter ASCII
    longint unsigned   cycle;

    function new(string name = "uvmt_opc_status_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        case (event_type)
            OPC_EV_GOOD_TRAP: return $sformatf("[STATUS] Tile%0d: GOOD TRAP ciclo=%0d",
                                    tile_id, cycle);
            OPC_EV_BAD_TRAP:  return $sformatf("[STATUS] Tile%0d: BAD TRAP code=0x%016h ciclo=%0d",
                                    tile_id, error_code, cycle);
            OPC_EV_UART_CHAR: return $sformatf("[UART] '%c' (0x%02h)",
                                    uart_char, uart_char);
            default:          return "[STATUS] evento desconhecido";
        endcase
    endfunction

endclass : uvmt_opc_status_seq_item_c

`endif // __UVMT_OPC_STATUS_SEQ_ITEM_SV__
