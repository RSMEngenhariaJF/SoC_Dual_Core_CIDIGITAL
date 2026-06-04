// ============================================================================
// uvmt_opc_coh2_pkg.sv
// Pacote do testbench v2 de coerência OpenPiton+CVA6.
//
// Importa uvmt_opc_pkg (v1) para reutilizar todos os agentes, seq items e
// tipos existentes, e adiciona as novas classes v2.
//
// Ordem de inclusão (dependências):
//   1. uvmt_opc_coh2_cfg.sv         — estende uvmt_opc_cfg_c
//   2. uvmt_opc_sb_seq_item.sv      — novo seq item do store buffer
//   3. uvmt_opc_sb_mon.sv           — monitor passivo do store buffer
//   4. uvmt_opc_sb_agent.sv         — agente passivo do store buffer
//   5. uvmt_opc_coh2_scoreboard.sv  — estende uvmt_opc_scoreboard_c
//   6. uvmt_opc_coh2_seq.sv         — estende uvmt_opc_base_seq_c
//   7. uvmt_opc_coh2_env.sv         — ambiente standalone v2
//   8. uvmt_opc_coh2_test.sv        — teste com FIX config_db
// ============================================================================
`ifndef __UVMT_OPC_COH2_PKG_SV__
`define __UVMT_OPC_COH2_PKG_SV__

package uvmt_opc_coh2_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Importa o pacote v1 — disponibiliza todos os tipos existentes
    import uvmt_opc_pkg::*;

    // =========================================================================
    // Configuração v2
    // =========================================================================
    `include "uvmt_opc_coh2_cfg.sv"

    // =========================================================================
    // Store Buffer Monitor Agent
    // =========================================================================
    `include "uvmt_opc_sb_seq_item.sv"
    `include "uvmt_opc_sb_mon.sv"
    `include "uvmt_opc_sb_agent.sv"

    // =========================================================================
    // Scoreboard e sequência aprimorados
    // =========================================================================
    `include "uvmt_opc_coh2_scoreboard.sv"
    `include "uvmt_opc_coh2_seq.sv"

    // =========================================================================
    // Ambiente e teste v2
    // =========================================================================
    `include "uvmt_opc_coh2_env.sv"
    `include "uvmt_opc_coh2_test.sv"

endpackage : uvmt_opc_coh2_pkg

`endif // __UVMT_OPC_COH2_PKG_SV__
