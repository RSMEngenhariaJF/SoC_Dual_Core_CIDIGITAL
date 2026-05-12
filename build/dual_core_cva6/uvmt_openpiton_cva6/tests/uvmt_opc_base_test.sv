// ============================================================================
// uvmt_opc_base_test.sv
// Teste base: cria o ambiente, configura via cfg, levanta/abaixa objections.
// Todos os outros testes herdam desta classe.
// ============================================================================
`ifndef __UVMT_OPC_BASE_TEST_SV__
`define __UVMT_OPC_BASE_TEST_SV__

class uvmt_opc_base_test_c extends uvm_test;

    `uvm_component_utils(uvmt_opc_base_test_c)

    uvmt_opc_env_c   env;
    uvmt_opc_cfg_c   cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Cria o objeto de configuracao; subclasses podem sobrescrever restricoes
    virtual function uvmt_opc_cfg_c create_cfg();
        uvmt_opc_cfg_c c = uvmt_opc_cfg_c::type_id::create("cfg");
        void'(c.randomize());
        return c;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = create_cfg();
        // Le test_binary do plusarg: +TEST_BINARY=path/to/test.vmh
        void'($value$plusargs("TEST_BINARY=%s",  cfg.test_binary));
        void'($value$plusargs("TIMEOUT=%0d",     cfg.timeout_cycles));
        // Publica no config_db para todos os componentes descendentes
        uvm_config_db #(uvmt_opc_cfg_c)::set(this, "*", "cfg", cfg);
        env = uvmt_opc_env_c::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        uvmt_opc_base_seq_c seq;
        phase.raise_objection(this, "Teste iniciado");
        seq = uvmt_opc_base_seq_c::type_id::create("base_seq");
        seq.start(env.clk_rst_agent.seqr);
        // Aguarda fim - objection abaixada pelo scoreboard ao detectar
        // good_trap nos tiles do finish_mask, ou pelo timeout do tb.
        phase.drop_objection(this, "Sequencia aplicada");
    endtask

    function void final_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "=== TESTE CONCLUIDO ===", UVM_NONE)
    endfunction

endclass : uvmt_opc_base_test_c

`endif // __UVMT_OPC_BASE_TEST_SV__
