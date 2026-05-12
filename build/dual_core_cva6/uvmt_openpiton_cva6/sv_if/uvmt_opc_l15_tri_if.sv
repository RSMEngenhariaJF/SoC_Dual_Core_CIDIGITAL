// ============================================================================
// uvmt_opc_l15_tri_if.sv
// Interface L1.5 TRI (Transaction-Response Interface).
//
// Conecta o adaptador de cache do CVA6 (ariane_l15_adapter) ao L1.5 do
// P-Mesh. Fluxo:
//   1. CVA6 -> L1.5 : val=1, reqtype, address, data  ->  ack=1
//   2. L1.5 -> CVA6 : val=1, returntype, returndata  ->  ack=1
//   3. L1.5 -> CVA6 : invalidacoes assincronas (inval_valid, inval_address)
//
// Referencia: piton/design/chip/tile/ariane/src/cache_subsystem/
//             ariane_l15_adapter.sv  (OpenPiton+Ariane branch)
// ============================================================================
`ifndef __UVMT_OPC_L15_TRI_IF_SV__
`define __UVMT_OPC_L15_TRI_IF_SV__

interface uvmt_opc_l15_tri_if #(
    parameter int unsigned ADDR_W = 40,
    parameter int unsigned DATA_W = 64
)(
    input logic clk,
    input logic rst_n
);

    // ---- Requisicao: CVA6 -> L1.5 -------------------------------------------
    // Tipos de requisicao (de l15.h):
    //   4'h0=LOAD, 4'h1=STORE, 4'h8=IFILL, 4'hC=AMO, 4'hE=FLUSH
    logic [3:0]          transducer_l15_reqtype;
    logic                transducer_l15_val;
    logic                transducer_l15_ack;          // L1.5 aceita req
    logic [ADDR_W-1:0]   transducer_l15_address;
    logic [DATA_W-1:0]   transducer_l15_data;
    logic [DATA_W-1:0]   transducer_l15_data_next_entry;
    logic [1:0]          transducer_l15_size;         // 0=B,1=HW,2=W,3=DW
    logic                transducer_l15_nc;            // non-cacheable
    logic [3:0]          transducer_l15_amo_op;
    logic [2:0]          transducer_l15_threadid;
    logic                transducer_l15_prefetch;
    logic                transducer_l15_blockstore;
    logic                transducer_l15_blockinitstore;
    logic [1:0]          transducer_l15_l1rplway;

    // ---- Resposta: L1.5 -> CVA6 ---------------------------------------------
    // Tipos de retorno:
    //   4'h0=LOAD_RET, 4'h3=ST_ACK, 4'h4=IFILL_RET, 4'h7=AMO_RET
    logic [3:0]          l15_transducer_returntype;
    logic                l15_transducer_val;
    logic                l15_transducer_ack;           // CVA6 aceita resp
    logic [DATA_W-1:0]   l15_transducer_returndata_0;
    logic [DATA_W-1:0]   l15_transducer_returndata_1;
    logic                l15_transducer_returnnc;
    logic [1:0]          l15_transducer_returnsize;
    logic [2:0]          l15_transducer_threadid;

    // ---- Invalidacoes assincronas: L1.5 -> CVA6 L1 -------------------------
    logic                l15_transducer_inval_valid;
    logic [ADDR_W-1:0]   l15_transducer_inval_address;
    logic                l15_transducer_inval_way;
    logic                l15_transducer_inval_icache_all_way;
    logic                l15_transducer_inval_dcache_all_way;

    // Clocking block para monitor passivo
    clocking mon_cb @(posedge clk);
        input transducer_l15_reqtype;
        input transducer_l15_val;
        input transducer_l15_ack;
        input transducer_l15_address;
        input transducer_l15_data;
        input transducer_l15_size;
        input transducer_l15_nc;
        input transducer_l15_amo_op;

        input l15_transducer_returntype;
        input l15_transducer_val;
        input l15_transducer_ack;
        input l15_transducer_returndata_0;
        input l15_transducer_returndata_1;

        input l15_transducer_inval_valid;
        input l15_transducer_inval_address;
        input l15_transducer_inval_way;
        input l15_transducer_inval_icache_all_way;
        input l15_transducer_inval_dcache_all_way;
    endclocking

    modport mon_mp (clocking mon_cb, input clk, rst_n);

    // ---- Assercoes de protocolo TRI ----------------------------------------

    // Requisicao deve permanecer ate ser aceita
    property p_req_stable;
        @(posedge clk) disable iff (!rst_n)
        (transducer_l15_val && !transducer_l15_ack) |=>
        (transducer_l15_val && $stable(transducer_l15_reqtype) &&
         $stable(transducer_l15_address));
    endproperty

    // Resposta deve permanecer ate ser aceita
    property p_rsp_stable;
        @(posedge clk) disable iff (!rst_n)
        (l15_transducer_val && !l15_transducer_ack) |=>
        (l15_transducer_val && $stable(l15_transducer_returntype));
    endproperty

    // reqtype sem X quando val=1
    property p_no_x_req;
        @(posedge clk) disable iff (!rst_n)
        transducer_l15_val |-> !$isunknown(transducer_l15_reqtype);
    endproperty

    AST_TRI_REQ_STABLE : assert property (p_req_stable);
    AST_TRI_RSP_STABLE : assert property (p_rsp_stable);
    AST_TRI_NO_X       : assert property (p_no_x_req);

endinterface : uvmt_opc_l15_tri_if

`endif // __UVMT_OPC_L15_TRI_IF_SV__
