// ============================================================================
// uvmt_opc_coherence_test.sv
// Teste de stress de coerencia de cache para configuracao multi-tile.
//
// Usa os testes assembly "ariane_tile16_simple" do piton/verif/diag/
// que exercitam sincronizacao por AMO ADD entre multiplos tiles.
//
// Requer: NUM_X_TILES * NUM_Y_TILES >= 2
//
// Uso:
//   set_property xsim.simulate.xsim.more_options \
//     {-testplusarg UVM_TESTNAME=uvmt_opc_coherence_test_c \
//      -testplusarg NUM_X_TILES=2 -testplusarg NUM_Y_TILES=1 \
//      -testplusarg TEST_BINARY=ariane_tile2_amo_test.vmh} [get_filesets sim_1]
// ============================================================================
`ifndef __UVMT_OPC_COHERENCE_TEST_SV__
`define __UVMT_OPC_COHERENCE_TEST_SV__

class uvmt_opc_coherence_test_c extends uvmt_opc_base_test_c;

    `uvm_component_utils(uvmt_opc_coherence_test_c)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Sobrescreve create_cfg para configurar topologia multi-tile
    // NOTA XSim: constraint_mode() em constraint especifico via handle nao e
    // suportado no XSim. Usamos atribuicao direta em vez de randomize+constraint.
    virtual function uvmt_opc_cfg_c create_cfg();
        uvmt_opc_cfg_c c = uvmt_opc_cfg_c::type_id::create("cfg");
        // Configura topologia 2x1 diretamente (sem constraint_mode)
        c.num_x_tiles      = 2;
        c.num_y_tiles      = 1;
        c.finish_mask      = 64'h3;   // tiles 0 e 1 devem completar
        c.enable_coh_check = 1;
        c.timeout_cycles   = 5_000_000;
        `uvm_info("OPC_COH_TEST",
            $sformatf("[CFG] %0dx%0d tiles | finish_mask=0x%0h",
                c.num_x_tiles, c.num_y_tiles, c.finish_mask),
            UVM_LOW)
        return c;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Aceita override de topologia via plusargs
        begin
            string x_str, y_str;
            if ($value$plusargs("NUM_X_TILES=%s", x_str)) cfg.num_x_tiles = x_str.atoi();
            if ($value$plusargs("NUM_Y_TILES=%s", y_str)) cfg.num_y_tiles = y_str.atoi();
        end
        if (cfg.num_tiles() < 2) begin
            `uvm_warning("OPC_COH_TEST",
                "Teste de coerencia com menos de 2 tiles - coerencia inter-tile nao sera exercitada")
        end
        `uvm_info("OPC_COH_TEST",
            $sformatf("Topologia: %0dx%0d = %0d tiles | finish_mask=0x%0h",
                cfg.num_x_tiles, cfg.num_y_tiles,
                cfg.num_tiles(), cfg.finish_mask),
            UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        uvmt_opc_coherence_seq_c seq;
        phase.raise_objection(this, "Coherence test iniciado");

        seq = uvmt_opc_coherence_seq_c::type_id::create("coh_seq");
        seq.start(env.clk_rst_agent.seqr);

        // Aguarda todos os tiles atingirem GOOD_TRAP ou timeout
        #(cfg.timeout_cycles * cfg.clk_period_ps * 1ps);
        phase.drop_objection(this, "Coherence test timeout");
    endtask

endclass : uvmt_opc_coherence_test_c

`endif // __UVMT_OPC_COHERENCE_TEST_SV__
