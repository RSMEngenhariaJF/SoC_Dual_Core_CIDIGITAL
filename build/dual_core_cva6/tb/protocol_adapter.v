// Protocol adapter: converte o protocolo yummy (credit-based) do chip.v
// para o protocolo val/rdy (handshake) do noc_axi4_bridge.
//
// Protocolo yummy (OpenPiton):
//   Remetente: envia dados quando valid=1.
//   Receptor:  confirma consumo no ciclo SEGUINTE via yummy=1.
//
// Protocolo val/rdy (AXI-like):
//   Transação ocorre quando val=1 E rdy=1 no mesmo ciclo.
//
// credit_to_valrdy : chip(yummy) → bridge(val/rdy)  [canal NOC1 — requisições]
// valrdy_to_credit : bridge(val/rdy) → chip(yummy)  [canal NOC2 — respostas]

`include "define.tmp.h"

module protocol_adapter (
    input  wire                        clk,
    input  wire                        rst_n,

    // ---------- Lado chip (protocolo yummy) ----------
    // NOC1: chip envia requisições de memória
    input  wire [`NOC_DATA_WIDTH-1:0]  chip_noc1_data,
    input  wire                        chip_noc1_valid,
    output wire                        chip_noc1_yummy,   // feedback → chip

    // NOC2: chip recebe respostas da memória
    output wire [`NOC_DATA_WIDTH-1:0]  chip_noc2_data,
    output wire                        chip_noc2_valid,
    input  wire                        chip_noc2_yummy,   // feedback ← chip

    // ---------- Lado bridge (protocolo val/rdy) ----------
    // Saída para bridge (requisições)
    output wire [`NOC_DATA_WIDTH-1:0]  bridge_req_data,
    output wire                        bridge_req_valid,
    input  wire                        bridge_req_rdy,

    // Entrada do bridge (respostas)
    input  wire [`NOC_DATA_WIDTH-1:0]  bridge_resp_data,
    input  wire                        bridge_resp_valid,
    output wire                        bridge_resp_rdy
);

// NOC1: chip (yummy) → bridge (val/rdy)
credit_to_valrdy #() u_noc1_c2v (
    .clk       (clk),
    .reset     (~rst_n),
    .data_in   (chip_noc1_data),
    .valid_in  (chip_noc1_valid),
    .yummy_in  (chip_noc1_yummy),
    .data_out  (bridge_req_data),
    .valid_out (bridge_req_valid),
    .ready_out (bridge_req_rdy)
);

// NOC2: bridge (val/rdy) → chip (yummy)
valrdy_to_credit #() u_noc2_v2c (
    .clk       (clk),
    .reset     (~rst_n),
    .data_in   (bridge_resp_data),
    .valid_in  (bridge_resp_valid),
    .ready_in  (bridge_resp_rdy),
    .data_out  (chip_noc2_data),
    .valid_out (chip_noc2_valid),
    .yummy_out (chip_noc2_yummy)
);

endmodule
