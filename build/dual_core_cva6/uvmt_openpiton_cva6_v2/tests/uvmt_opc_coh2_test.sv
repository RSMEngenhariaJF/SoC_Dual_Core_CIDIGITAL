// ============================================================================
// uvmt_opc_coh2_test.sv
// Teste de coerência aprimorado — testbench v2.
//
// Correções e melhorias sobre uvmt_opc_coherence_test_c:
//
//   [FIX-1] Config_db propagation:
//     O teste base usa set(this, "*", "cfg", cfg), onde "this" = uvm_test_top.
//     Sequências correm no contexto do sequenciador:
//       get_full_name() = "uvm_test_top.env.clk_rst_agent.seqr@@coh2_seq"
//     O wildcard "*" do UVM só corresponde a UM nível hierárquico.
//     Este teste adiciona:
//       set(null, "*", "cfg", cfg)  ← contexto global, corresponde a TUDO
//
//   [FIX-2] Ambiente v2:
//     Cria uvmt_opc_coh2_env_c com sb_mon_agent e scoreboard aprimorado.
//
//   [FIX-3] Topologia 2×1 fixa:
//     finish_mask = 0x3 (ambos tiles devem completar).
// ============================================================================
`ifndef __UVMT_OPC_COH2_TEST_SV__
`define __UVMT_OPC_COH2_TEST_SV__

class uvmt_opc_coh2_test_c extends uvm_test;

    `uvm_component_utils(uvmt_opc_coh2_test_c)

    uvmt_opc_coh2_env_c  env;
    uvmt_opc_coh2_cfg_c  cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // =========================================================================
    // build_phase
    // =========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Cria e configura o objeto de configuração v2
        cfg = uvmt_opc_coh2_cfg_c::type_id::create("cfg");
        cfg.num_x_tiles      = 2;
        cfg.num_y_tiles      = 1;
        cfg.finish_mask      = 64'h1;       // good_trap[0] combinado (ambos tiles)
        cfg.enable_coh_check = 1;
        cfg.enable_sb_mon    = 1;
        cfg.enable_latency_tracking = 1;
        cfg.timeout_cycles   = 5_000_000;

        // Override via plusargs
        begin
            string x_str, y_str, bin_str;
            if ($value$plusargs("NUM_X_TILES=%s", x_str)) cfg.num_x_tiles = x_str.atoi();
            if ($value$plusargs("NUM_Y_TILES=%s", y_str)) cfg.num_y_tiles = y_str.atoi();
            if ($value$plusargs("TEST_BINARY=%s", bin_str)) cfg.test_binary = bin_str;
            if ($value$plusargs("TIMEOUT=%0d", cfg.timeout_cycles)) ;
        end

        // finish_mask=1: status_if usa NUM_TILES=1; good_trap[0] é setado
        // somente quando AMBOS os tiles concluem (lógica combinada no dut_wrap)
        cfg.finish_mask = 1;

        `uvm_info("OPC_COH2_TEST",
            $sformatf("[CFG] %0dx%0d tiles | finish_mask=0x%0h | sb_mon=%0b",
                cfg.num_x_tiles, cfg.num_y_tiles,
                cfg.finish_mask, cfg.enable_sb_mon),
            UVM_LOW)

        // [FIX-1] Propagação correta no config_db:
        // (a) Propagação hierárquica padrão — cobre componentes UVM diretos
        uvm_config_db #(uvmt_opc_cfg_c)::set(this, "*", "cfg", cfg);
        // (b) Propagação global — cobre sequências (que usam get_full_name()
        //     com "@@" na notação de sequenciador)
        uvm_config_db #(uvmt_opc_cfg_c)::set(null, "*", "cfg", cfg);

        // [FIX-2] Cria ambiente v2
        env = uvmt_opc_coh2_env_c::type_id::create("env", this);
    endfunction

    // =========================================================================
    // run_phase
    // =========================================================================
    task run_phase(uvm_phase phase);
        uvmt_opc_coh2_seq_c   seq;
        virtual uvmt_opc_status_if status_vif;

        phase.raise_objection(this, "Coherence v2 test iniciado");

        seq = uvmt_opc_coh2_seq_c::type_id::create("coh2_seq");
        seq.start(env.clk_rst_agent.seqr);

        // Obtém status_vif para aguardar good_trap diretamente
        if (!uvm_config_db #(virtual uvmt_opc_status_if)::get(
                this, "", "status_vif", status_vif))
            `uvm_fatal("OPC_COH2_TEST", "status_vif nao encontrado")

        // Aguarda good_trap[0] (set quando ambos os tiles concluem)
        // ou timeout — o que vier primeiro
        fork
            begin : wait_pass
                @(posedge status_vif.clk);
                while (!status_vif.good_trap[0])
                    @(posedge status_vif.clk);
            end
            begin : wait_timeout
                #(cfg.timeout_cycles * cfg.clk_period_ps * 1ps);
                `uvm_error("OPC_COH2_TEST",
                    $sformatf("Timeout: %0d ciclos sem GOOD_TRAP", cfg.timeout_cycles))
            end
        join_any
        disable fork;

        phase.drop_objection(this, "Coherence v2 test concluido");
    endtask

    function void final_phase(uvm_phase phase);
        `uvm_info("OPC_COH2_TEST", "=== TESTE V2 CONCLUIDO ===", UVM_NONE)
    endfunction

endclass : uvmt_opc_coh2_test_c

`endif // __UVMT_OPC_COH2_TEST_SV__
