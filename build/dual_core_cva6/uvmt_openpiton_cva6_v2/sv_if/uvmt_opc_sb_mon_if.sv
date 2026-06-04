// ============================================================================
// uvmt_opc_sb_mon_if.sv
// Interface de monitoramento do store buffer (sb_mon) para os dois tiles.
//
// Conectada pelo dut_wrap v2 aos sinais internos:
//   SB0: store_buffer_i do tile 0 (hart 0)
//   SB1: store_buffer_i do tile 1 (hart 1)
//
// Usada pelo uvmt_opc_sb_mon_c para capturar commits de store em tempo real.
// ============================================================================
`ifndef __UVMT_OPC_SB_MON_IF_SV__
`define __UVMT_OPC_SB_MON_IF_SV__

interface uvmt_opc_sb_mon_if (input logic clk, input logic rst_n);

    // ---- Tile 0 store buffer commit ------------------------------------------
    logic        sb0_commit;      // pulso: store commitado pelo tile 0
    logic [55:0] sb0_addr;        // endereco fisico do store (56-bit PLEN)
    logic [63:0] sb0_data;        // dado do store

    // ---- Tile 1 store buffer commit ------------------------------------------
    logic        sb1_commit;      // pulso: store commitado pelo tile 1
    logic [55:0] sb1_addr;        // endereco fisico do store
    logic [63:0] sb1_data;        // dado do store

    // ---- Clocking block para monitor (leitura sincrona) ----------------------
    clocking sb_cb @(posedge clk);
        input sb0_commit, sb0_addr, sb0_data;
        input sb1_commit, sb1_addr, sb1_data;
    endclocking

endinterface : uvmt_opc_sb_mon_if

`endif // __UVMT_OPC_SB_MON_IF_SV__
