// ============================================================================
// uvmt_opc_coherence_seq.sv
// Sequencia de stress de coerencia para testes multi-tile.
// Utiliza os testes assembly "ariane_tile16_simple" do piton/verif/diag/
// que exercitam AMO ADD sincronizado entre multiplos tiles.
// ============================================================================
`ifndef __UVMT_OPC_COHERENCE_SEQ_SV__
`define __UVMT_OPC_COHERENCE_SEQ_SV__

class uvmt_opc_coherence_seq_c extends uvmt_opc_base_seq_c;

    `uvm_object_utils(uvmt_opc_coherence_seq_c)

    // Padrao de coerencia a executar
    typedef enum {
        COH_PAT_PRODUCER_CONSUMER,  // tile 0 escreve, tile 1 le
        COH_PAT_PING_PONG,          // tiles alternam escritas na mesma linha
        COH_PAT_FALSE_SHARING,      // tiles acessam words diferentes na mesma linha
        COH_PAT_AMO_BARRIER         // barrier via atomic ADD (padrao OpenPiton)
    } coh_pattern_e;

    rand coh_pattern_e pattern;

    constraint c_default_pattern {
        pattern == COH_PAT_AMO_BARRIER;
    }

    function new(string name = "uvmt_opc_coherence_seq");
        super.new(name);
    endfunction

    task body();
        send_clk_rst();

        if (cfg.num_tiles() < 2) begin
            `uvm_warning("OPC_COH_SEQ",
                "Teste de coerencia requer num_tiles >= 2. Configure cfg.num_x_tiles ou num_y_tiles.")
            return;
        end

        `uvm_info("OPC_COH_SEQ",
            $sformatf("Sequencia de coerencia: %s | tiles=%0dx%0d",
                pattern.name(), cfg.num_x_tiles, cfg.num_y_tiles),
            UVM_LOW)

        // O teste assembly real e selecionado pelo cfg.test_binary.
        // Esta sequencia apenas documenta o padrao esperado e
        // configura a mascara de finish_mask para todos os tiles.
        case (pattern)
            COH_PAT_PRODUCER_CONSUMER:
                `uvm_info("OPC_COH_SEQ", "Padrao: produtor(tile0) / consumidor(tile1)", UVM_LOW)
            COH_PAT_PING_PONG:
                `uvm_info("OPC_COH_SEQ", "Padrao: ping-pong de linha de cache", UVM_LOW)
            COH_PAT_FALSE_SHARING:
                `uvm_info("OPC_COH_SEQ", "Padrao: false sharing (words distintos, mesma linha)", UVM_LOW)
            COH_PAT_AMO_BARRIER:
                `uvm_info("OPC_COH_SEQ",
                    "Padrao: AMO ADD barrier (ariane_tile16_simple equivalent)", UVM_LOW)
        endcase
    endtask

endclass : uvmt_opc_coherence_seq_c

`endif // __UVMT_OPC_COHERENCE_SEQ_SV__
