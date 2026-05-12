// ============================================================================
// uvmt_opc_asm_test.sv
// Teste para execucao de programas assembly/C do piton/verif/diag/.
//
// Equivale ao flow: sims -sys=manycore -ariane -vlt_run <testname>
// Carrega o binario compilado (.vmh) via +TEST_BINARY e aguarda GOOD_TRAP.
//
// Uso (Vivado TCL Console):
//   set_property xsim.simulate.xsim.more_options \
//     {-testplusarg UVM_TESTNAME=uvmt_opc_asm_test_c \
//      -testplusarg TEST_BINARY=rv64ui-p-addi.vmh} [get_filesets sim_1]
//   restart ; run 50000us
// ============================================================================
`ifndef __UVMT_OPC_ASM_TEST_SV__
`define __UVMT_OPC_ASM_TEST_SV__

class uvmt_opc_asm_test_c extends uvmt_opc_base_test_c;

    `uvm_component_utils(uvmt_opc_asm_test_c)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        // Herda build_phase do base_test (cria env, le plusargs)
        super.build_phase(phase);

        // Para testes assembly de tile unico, restricao padrao (1x1) e ok.
        // Para testes multi-tile (ariane_tile16_*), sobrescreva via plusargs:
        //   +NUM_X_TILES=4 +NUM_Y_TILES=4
        begin
            string x_str, y_str;
            if ($value$plusargs("NUM_X_TILES=%s", x_str))
                cfg.num_x_tiles = x_str.atoi();
            if ($value$plusargs("NUM_Y_TILES=%s", y_str))
                cfg.num_y_tiles = y_str.atoi();
        end

        if (cfg.test_binary == "") begin
            `uvm_warning("OPC_ASM_TEST",
                "TEST_BINARY nao definido. Use +TEST_BINARY=caminho/para/teste.vmh")
        end else begin
            `uvm_info("OPC_ASM_TEST",
                $sformatf("Binario de teste: %s", cfg.test_binary), UVM_LOW)
        end
    endfunction

    task run_phase(uvm_phase phase);
        uvmt_opc_asm_test_seq_c seq;
        phase.raise_objection(this, "ASM test iniciado");

        seq = uvmt_opc_asm_test_seq_c::type_id::create("asm_seq");
        seq.test_name = cfg.test_binary;
        seq.start(env.clk_rst_agent.seqr);

        // Aguarda GOOD_TRAP via timeout do watchdog do tb.
        // O scoreboard abaixa a objection ao detectar o finish_mask completo.
        // Aqui aguardamos o timeout maximo configurado.
        #(cfg.timeout_cycles * cfg.clk_period_ps * 1ps);
        phase.drop_objection(this, "ASM test timeout atingido");
    endtask

endclass : uvmt_opc_asm_test_c

`endif // __UVMT_OPC_ASM_TEST_SV__
