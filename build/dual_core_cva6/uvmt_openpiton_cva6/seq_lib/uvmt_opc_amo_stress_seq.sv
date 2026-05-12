// ============================================================================
// uvmt_opc_amo_stress_seq.sv
// Sequencia de stress para operacoes atomicas (AMO) do RISC-V.
// Exercita as operacoes AMO (LR/SC, AMOSWAP, AMOADD, etc.)
// que passam pelo L1.5 com tratamento especial (inval + encaminhar a L2).
// ============================================================================
`ifndef __UVMT_OPC_AMO_STRESS_SEQ_SV__
`define __UVMT_OPC_AMO_STRESS_SEQ_SV__

class uvmt_opc_amo_stress_seq_c extends uvmt_opc_base_seq_c;

    `uvm_object_utils(uvmt_opc_amo_stress_seq_c)

    // Numero de iteracoes AMO a executar no binario de teste
    rand int unsigned num_amo_iters;
    // Usar LR/SC (1) ou AMO diretas (0)
    rand bit use_lr_sc;

    constraint c_iters { num_amo_iters inside {[100:10_000]}; }

    function new(string name = "uvmt_opc_amo_stress_seq");
        super.new(name);
    endfunction

    task body();
        send_clk_rst();
        `uvm_info("OPC_AMO_SEQ",
            $sformatf("AMO stress: iters=%0d | lr_sc=%0b | binary='%s'",
                num_amo_iters, use_lr_sc, cfg.test_binary),
            UVM_LOW)
        // O binario compilado dos testes amo do piton/verif/diag/
        // (ariane_tile1_amo_tests_p) e carregado pelo DUT wrapper.
        // Esta sequencia controla apenas os parametros de timing/reset.
    endtask

endclass : uvmt_opc_amo_stress_seq_c

`endif // __UVMT_OPC_AMO_STRESS_SEQ_SV__
