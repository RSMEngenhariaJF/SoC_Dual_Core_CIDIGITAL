// ============================================================================
// uvmt_opc_noc_if.sv
// Interface SystemVerilog para as tres redes NoC do P-Mesh (OpenPiton).
//
// NoC1 = Requisicoes  (tile -> rede)
// NoC2 = Respostas    (rede -> tile)
// NoC3 = Forwarding / Invalidacoes
//
// Protocolo: valid/ready handshake, flits de largura NOC_DATA_W bits.
// Header flit: [7:0]=msg_type, [15:8]=pkt_len, [47:40]=dst_x, [55:48]=dst_y
// ============================================================================
`ifndef __UVMT_OPC_NOC_IF_SV__
`define __UVMT_OPC_NOC_IF_SV__

interface uvmt_opc_noc_if #(
    parameter int unsigned NOC_DATA_W = 64
)(
    input logic clk,
    input logic rst_n
);

    // ---- NoC1 (Requisicoes) ------------------------------------------------
    logic [NOC_DATA_W-1:0] noc1_out_data;   // tile -> rede
    logic                  noc1_out_valid;
    logic                  noc1_out_ready;   // backpressure

    logic [NOC_DATA_W-1:0] noc1_in_data;    // rede -> tile
    logic                  noc1_in_valid;
    logic                  noc1_in_ready;

    // ---- NoC2 (Respostas) --------------------------------------------------
    logic [NOC_DATA_W-1:0] noc2_out_data;
    logic                  noc2_out_valid;
    logic                  noc2_out_ready;

    logic [NOC_DATA_W-1:0] noc2_in_data;
    logic                  noc2_in_valid;
    logic                  noc2_in_ready;

    // ---- NoC3 (Forwarding / Invalidacoes) ----------------------------------
    logic [NOC_DATA_W-1:0] noc3_out_data;
    logic                  noc3_out_valid;
    logic                  noc3_out_ready;

    logic [NOC_DATA_W-1:0] noc3_in_data;
    logic                  noc3_in_valid;
    logic                  noc3_in_ready;

    // Clocking block para monitor passivo
    clocking mon_cb @(posedge clk);
        input noc1_out_data,  noc1_out_valid,  noc1_out_ready;
        input noc1_in_data,   noc1_in_valid,   noc1_in_ready;
        input noc2_out_data,  noc2_out_valid,  noc2_out_ready;
        input noc2_in_data,   noc2_in_valid,   noc2_in_ready;
        input noc3_out_data,  noc3_out_valid,  noc3_out_ready;
        input noc3_in_data,   noc3_in_valid,   noc3_in_ready;
    endclocking

    // Modport monitor
    modport mon_mp (
        clocking mon_cb,
        input clk, rst_n
    );

    // ---- Assercoes de protocolo (desabilitadas durante reset) ---------------

    // Estabilidade de flit: valid=1 e ready=0 -> data nao muda no ciclo seguinte
    property p_noc1_stable;
        @(posedge clk) disable iff (!rst_n)
        (noc1_out_valid && !noc1_out_ready) |=> $stable(noc1_out_data);
    endproperty

    property p_noc2_stable;
        @(posedge clk) disable iff (!rst_n)
        (noc2_out_valid && !noc2_out_ready) |=> $stable(noc2_out_data);
    endproperty

    property p_noc3_stable;
        @(posedge clk) disable iff (!rst_n)
        (noc3_out_valid && !noc3_out_ready) |=> $stable(noc3_out_data);
    endproperty

    // Sem X em valid fora de reset
    property p_no_x_valid;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown({noc1_out_valid, noc2_out_valid, noc3_out_valid});
    endproperty

    AST_NOC1_STABLE : assert property (p_noc1_stable);
    AST_NOC2_STABLE : assert property (p_noc2_stable);
    AST_NOC3_STABLE : assert property (p_noc3_stable);
    AST_NOC_NO_X    : assert property (p_no_x_valid);

endinterface : uvmt_opc_noc_if

`endif // __UVMT_OPC_NOC_IF_SV__
