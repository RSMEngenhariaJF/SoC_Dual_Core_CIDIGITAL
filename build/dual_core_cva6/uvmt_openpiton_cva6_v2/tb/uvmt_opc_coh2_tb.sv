// ============================================================================
// uvmt_opc_coh2_tb.sv
// Top-level do testbench UVM v2 de coerência OpenPiton+CVA6.
//
// Diferenças em relação a uvmt_opc_tb.sv (v1):
//   1. Instancia uvmt_opc_sb_mon_if (nova interface store buffer)
//   2. Instancia uvmt_opc_coh2_dut_wrap (FIX-1 per-tile trap + sb_mon_if)
//   3. Registra sb_mon_vif no config_db para o agente sb_mon
//   4. Inicia uvmt_opc_coh2_test_c por padrão (via UVM_TESTNAME)
// ============================================================================
`ifndef __UVMT_OPC_COH2_TB_SV__
`define __UVMT_OPC_COH2_TB_SV__

`timescale 1ns / 1ps

module uvmt_opc_coh2_tb;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import uvmt_opc_pkg::*;
    import uvmt_opc_coh2_pkg::*;

    // =========================================================================
    // Parâmetros de topologia (2×1 tiles)
    // =========================================================================
    localparam int unsigned NUM_X_TILES = 2;
    localparam int unsigned NUM_Y_TILES = 1;
    localparam int unsigned NUM_TILES   = NUM_X_TILES * NUM_Y_TILES;

    // =========================================================================
    // Instâncias das interfaces
    // =========================================================================

    // clk_rst_if sem portas — clk e rst_n são sinais internos da interface
    uvmt_opc_clk_rst_if  clk_rst_if();

    uvmt_opc_noc_if #(
        .NOC_DATA_W (OPC_NOC_DATA_W)
    ) noc_if (
        .clk   (clk_rst_if.clk),
        .rst_n (clk_rst_if.rst_n)
    );

    uvmt_opc_l15_tri_if #(
        .ADDR_W (OPC_ADDR_W),
        .DATA_W (OPC_DATA_W)
    ) l15_tri_if (
        .clk   (clk_rst_if.clk),
        .rst_n (clk_rst_if.rst_n)
    );

    // NUM_TILES não é passado explicitamente para preservar compatibilidade de tipo
    // com virtual uvmt_opc_status_if (default NUM_TILES=1) usado nos monitors v1.
    // O dut_wrap rastreia cada tile internamente e combina em good_trap[0].
    uvmt_opc_status_if status_if (
        .clk   (clk_rst_if.clk),
        .rst_n (clk_rst_if.rst_n)
    );

    // [ADD-1] Interface store buffer monitor (nova no v2)
    uvmt_opc_sb_mon_if sb_mon_if (
        .clk   (clk_rst_if.clk),
        .rst_n (clk_rst_if.rst_n)
    );

    // =========================================================================
    // Instância do DUT wrapper v2
    // =========================================================================
    uvmt_opc_coh2_dut_wrap #(
        .NUM_X_TILES (NUM_X_TILES),
        .NUM_Y_TILES (NUM_Y_TILES)
    ) dut_wrap (
        .clk_rst_if (clk_rst_if),
        .noc_if     (noc_if),
        .l15_tri_if (l15_tri_if),
        .status_if  (status_if),
        .sb_mon_if  (sb_mon_if)   // [ADD-1]
    );

    // Clock e reset são gerados pelo driver UVM (uvmt_opc_clk_rst_drv_c),
    // como no testbench v1. Não há geração direta de clock/reset aqui.

    // =========================================================================
    // Configuração UVM: registra interfaces no config_db
    // =========================================================================
    initial begin
        // Interfaces padrão (v1)
        uvm_config_db #(virtual uvmt_opc_clk_rst_if)::set(
            null, "uvm_test_top.*", "clk_rst_vif", clk_rst_if);
        uvm_config_db #(virtual uvmt_opc_noc_if)::set(
            null, "uvm_test_top.*", "noc_vif", noc_if);
        uvm_config_db #(virtual uvmt_opc_l15_tri_if)::set(
            null, "uvm_test_top.*", "l15_tri_vif", l15_tri_if);
        uvm_config_db #(virtual uvmt_opc_status_if)::set(
            null, "uvm_test_top.*", "status_vif", status_if);
        // Registro extra para o próprio teste (get(this,"") busca "uvm_test_top")
        uvm_config_db #(virtual uvmt_opc_status_if)::set(
            null, "uvm_test_top", "status_vif", status_if);

        // [ADD-1] Interface store buffer monitor (nova no v2)
        uvm_config_db #(virtual uvmt_opc_sb_mon_if)::set(
            null, "uvm_test_top.*", "sb_mon_vif", sb_mon_if);

        // Inicia simulação UVM
        run_test("uvmt_opc_coh2_test_c");
    end

    // =========================================================================
    // Watchdog de timeout global
    // =========================================================================
    initial begin : timeout_watchdog
        longint unsigned timeout_cycles;
        string timeout_str;

        if ($value$plusargs("TIMEOUT=%s", timeout_str))
            timeout_cycles = timeout_str.atoi();
        else
            timeout_cycles = 5_000_000;

        @(posedge clk_rst_if.clk);
        repeat (timeout_cycles) @(posedge clk_rst_if.clk);

        `uvm_fatal("OPC_COH2_TIMEOUT",
            $sformatf("Timeout: %0d ciclos sem GOOD_TRAP", timeout_cycles))
    end

endmodule : uvmt_opc_coh2_tb

`endif // __UVMT_OPC_COH2_TB_SV__
