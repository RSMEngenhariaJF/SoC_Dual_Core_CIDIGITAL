// ============================================================================
// uvmt_opc_tb.sv
// Modulo top-level do testbench UVM para OpenPiton+CVA6.
//
// Responsabilidades:
//   1. Instanciar todas as interfaces SystemVerilog
//   2. Instanciar o DUT wrapper
//   3. Injetar interfaces no uvm_config_db
//   4. Invocar run_test() - seleciona o teste via +UVM_TESTNAME
//   5. Watchdog de timeout global
// ============================================================================
`ifndef __UVMT_OPC_TB_SV__
`define __UVMT_OPC_TB_SV__

`timescale 1ns/1ps

module uvmt_opc_tb;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import uvmt_opc_pkg::*;

    // Topologia configuravel via parametro de compilacao ou override Vivado
    parameter int unsigned NUM_X_TILES = 1;
    parameter int unsigned NUM_Y_TILES = 1;
    localparam int unsigned NUM_TILES  = NUM_X_TILES * NUM_Y_TILES;

    // =========================================================================
    // Instancias das interfaces SV
    // =========================================================================
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

    uvmt_opc_status_if #(
        .NUM_TILES (NUM_TILES)
    ) status_if (
        .clk   (clk_rst_if.clk),
        .rst_n (clk_rst_if.rst_n)
    );

    // =========================================================================
    // DUT Wrapper
    // =========================================================================
    uvmt_opc_dut_wrap #(
        .NUM_X_TILES (NUM_X_TILES),
        .NUM_Y_TILES (NUM_Y_TILES)
    ) dut_wrap (
        .clk_rst_if  (clk_rst_if),
        .noc_if      (noc_if),
        .l15_tri_if  (l15_tri_if),
        .status_if   (status_if)
    );

    // =========================================================================
    // Inicializacao UVM
    // =========================================================================
    initial begin : tb_start
        // Injeta handles das interfaces no config_db
        uvm_config_db #(virtual uvmt_opc_clk_rst_if)::set(
            null, "uvm_test_top.*", "clk_rst_vif", clk_rst_if);

        uvm_config_db #(virtual uvmt_opc_noc_if)::set(
            null, "uvm_test_top.*", "noc_vif", noc_if);

        uvm_config_db #(virtual uvmt_opc_l15_tri_if)::set(
            null, "uvm_test_top.*", "l15_tri_vif", l15_tri_if);

        uvm_config_db #(virtual uvmt_opc_status_if)::set(
            null, "uvm_test_top.*", "status_vif", status_if);

        // Cria e publica configuracao padrao (o teste pode sobrescrever)
        // NOTA XSim: variaveis locais em initial/final de modulo precisam de 'automatic'
        begin
            automatic uvmt_opc_cfg_c cfg;
            cfg = uvmt_opc_cfg_c::type_id::create("cfg");
            cfg.num_x_tiles = NUM_X_TILES;
            cfg.num_y_tiles = NUM_Y_TILES;
            cfg.finish_mask = (NUM_TILES > 1) ? (64'h1 << NUM_TILES) - 1 : 64'h1;
            void'($value$plusargs("TEST_BINARY=%s",  cfg.test_binary));
            void'($value$plusargs("TIMEOUT=%0d",     cfg.timeout_cycles));
            uvm_config_db #(uvmt_opc_cfg_c)::set(
                null, "uvm_test_top.*", "cfg", cfg);
        end

        // Seleciona e executa o teste via +UVM_TESTNAME=<classe>
        run_test();
    end

    // =========================================================================
    // Bloco final: imprime resultado pass/fail
    // =========================================================================
    final begin : tb_end
        automatic int errs;
        automatic int fatals;
        errs   = uvm_report_server::get_server().get_severity_count(UVM_ERROR);
        fatals = uvm_report_server::get_server().get_severity_count(UVM_FATAL);
        if (errs > 0 || fatals > 0) begin
            $display(">>> RESULTADO: FALHA (HIT BAD TRAP) - erros=%0d fatais=%0d <<<",
                     errs, fatals);
        end else begin
            $display(">>> RESULTADO: PASSOU (HIT GOOD TRAP) <<<");
        end
    end

    // =========================================================================
    // Watchdog de timeout global
    // Equivalente ao -rtl_timeout do sims do OpenPiton
    // Substituido pelo parametro +TIMEOUT=<ciclos>
    // =========================================================================
    initial begin : timeout_watchdog
        longint unsigned timeout_cycles;
        string           timeout_str;

        if ($value$plusargs("TIMEOUT=%s", timeout_str))
            timeout_cycles = timeout_str.atoi();
        else
            timeout_cycles = 5_000_000;

        // Aguarda clock ficar ativo
        @(posedge clk_rst_if.clk);
        repeat (timeout_cycles) @(posedge clk_rst_if.clk);

        `uvm_fatal("OPC_TB_TIMEOUT",
            $sformatf("Timeout: %0d ciclos sem GOOD_TRAP", timeout_cycles))
    end

endmodule : uvmt_opc_tb

`endif // __UVMT_OPC_TB_SV__
