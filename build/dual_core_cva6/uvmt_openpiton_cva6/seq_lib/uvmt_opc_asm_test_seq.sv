// ============================================================================
// uvmt_opc_asm_test_seq.sv
// Sequencia para execucao de testes assembly do piton/verif/diag/.
// Carrega o binario compilado e aguarda GOOD_TRAP ou BAD_TRAP.
// Equivale ao flow: sims -sys=manycore -ariane -vlt_run <testname>
// ============================================================================
`ifndef __UVMT_OPC_ASM_TEST_SEQ_SV__
`define __UVMT_OPC_ASM_TEST_SEQ_SV__

class uvmt_opc_asm_test_seq_c extends uvmt_opc_base_seq_c;

    `uvm_object_utils(uvmt_opc_asm_test_seq_c)

    // Nome do teste (ex: "rv64ui-p-addi", "dhrystone.riscv")
    string test_name = "";

    function new(string name = "uvmt_opc_asm_test_seq");
        super.new(name);
    endfunction

    task body();
        // 1. Aplica clock/reset
        send_clk_rst();

        `uvm_info("OPC_ASM_SEQ",
            $sformatf("Iniciando teste: '%s' | binary='%s'",
                test_name, cfg.test_binary),
            UVM_LOW)

        // 2. A carga do binario (vmh/hex) e feita no DUT wrapper via $readmemh.
        //    Esta sequencia apenas garante que o reset foi aplicado antes.
        //    Aguarda o monitor de status detectar o GOOD_TRAP ou BAD_TRAP.
        //    O controle de timeout e feito pelo watchdog do tb.

        // 3. Aguardar conclusao - a sequencia termina apos o clk/rst.
        //    O teste (uvm_test) monitora o trap via objection da fase run.
        `uvm_info("OPC_ASM_SEQ", "Clock/reset aplicados. Aguardando execucao do DUT.", UVM_LOW)
    endtask

endclass : uvmt_opc_asm_test_seq_c

`endif // __UVMT_OPC_ASM_TEST_SEQ_SV__
