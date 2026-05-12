// ============================================================================
// uvmt_opc_pkg.sv
// Pacote principal do ambiente UVM OpenPiton+CVA6.
// Importa uvm_pkg e inclui todos os arquivos de classe na ordem correta
// de dependencia (interfaces sao compiladas separadamente no tb).
//
// NOTA XSIM: O XSim compila este pacote com -L uvm, que disponibiliza
// uvm_pkg automaticamente. Nao e necessario path manual para uvm_pkg.sv.
// ============================================================================
`ifndef __UVMT_OPC_PKG_SV__
`define __UVMT_OPC_PKG_SV__

package uvmt_opc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // -------------------------------------------------------------------------
    // Parametros globais (usados por seq items, monitors e scoreboard)
    // -------------------------------------------------------------------------
    parameter int unsigned OPC_NOC_DATA_W = 64;
    parameter int unsigned OPC_ADDR_W     = 40;
    parameter int unsigned OPC_DATA_W     = 64;

    // =========================================================================
    // Objeto de configuracao
    // =========================================================================
    `include "uvmt_opc_cfg.sv"

    // =========================================================================
    // Sequence Items - devem ser incluidos antes dos monitors/drivers
    // =========================================================================
    `include "uvmt_opc_clk_rst_seq_item.sv"
    `include "uvmt_opc_noc_seq_item.sv"
    `include "uvmt_opc_l15_tri_seq_item.sv"
    `include "uvmt_opc_status_seq_item.sv"
    `include "uvmt_opc_uart_seq_item.sv"

    // =========================================================================
    // Monitors
    // =========================================================================
    `include "uvmt_opc_clk_rst_mon.sv"
    `include "uvmt_opc_noc_mon.sv"
    `include "uvmt_opc_l15_tri_mon.sv"
    `include "uvmt_opc_status_mon.sv"
    `include "uvmt_opc_uart_mon.sv"

    // =========================================================================
    // Drivers
    // =========================================================================
    `include "uvmt_opc_clk_rst_drv.sv"

    // =========================================================================
    // Agentes
    // =========================================================================
    `include "uvmt_opc_clk_rst_agent.sv"
    `include "uvmt_opc_noc_agent.sv"
    `include "uvmt_opc_l15_tri_agent.sv"
    `include "uvmt_opc_status_agent.sv"
    `include "uvmt_opc_uart_agent.sv"

    // =========================================================================
    // Scoreboard e Cobertura
    // =========================================================================
    `include "uvmt_opc_scoreboard.sv"
    `include "uvmt_opc_cov_model.sv"

    // =========================================================================
    // Sequencias
    // =========================================================================
    `include "uvmt_opc_base_seq.sv"
    `include "uvmt_opc_asm_test_seq.sv"
    `include "uvmt_opc_coherence_seq.sv"
    `include "uvmt_opc_amo_stress_seq.sv"

    // =========================================================================
    // Ambiente
    // =========================================================================
    `include "uvmt_opc_env.sv"

    // =========================================================================
    // Testes
    // =========================================================================
    `include "uvmt_opc_base_test.sv"
    `include "uvmt_opc_asm_test.sv"
    `include "uvmt_opc_coherence_test.sv"

endpackage : uvmt_opc_pkg

`endif // __UVMT_OPC_PKG_SV__
