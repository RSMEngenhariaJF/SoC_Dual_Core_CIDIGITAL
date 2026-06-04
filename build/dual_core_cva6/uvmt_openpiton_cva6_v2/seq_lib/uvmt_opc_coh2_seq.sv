// ============================================================================
// uvmt_opc_coh2_seq.sv
// Sequência aprimorada de coerência para testbench v2.
//
// Melhorias sobre uvmt_opc_coherence_seq_c:
//   1. Quatro padrões de coerência selecionáveis via parâmetro
//   2. Suporte a cfg do tipo uvmt_opc_coh2_cfg_c (com campos adicionais)
//   3. Log de início/fim de cada padrão para análise de latência
//   4. Verificação explícita de num_tiles >= 2
// ============================================================================
`ifndef __UVMT_OPC_COH2_SEQ_SV__
`define __UVMT_OPC_COH2_SEQ_SV__

class uvmt_opc_coh2_seq_c extends uvmt_opc_base_seq_c;

    `uvm_object_utils(uvmt_opc_coh2_seq_c)

    // Padrão de coerência selecionado
    typedef enum {
        COH2_FALSE_SHARING,       // tiles escrevem em words diferentes da mesma linha
        COH2_PRODUCER_CONSUMER,   // tile 0 escreve, tile 1 lê
        COH2_PING_PONG,           // tiles alternam escritas na mesma linha
        COH2_MULTI_LINE           // cada tile escreve em 2 linhas diferentes
    } coh2_pattern_e;

    rand coh2_pattern_e pattern;

    constraint c_default_pattern {
        pattern == COH2_FALSE_SHARING;
    }

    function new(string name = "uvmt_opc_coh2_seq");
        super.new(name);
    endfunction

    task body();
        uvmt_opc_coh2_cfg_c coh2_cfg;

        // Envia configuração de clock/reset
        send_clk_rst();

        // Tenta obter config v2 (pode ser cfg base se não disponível)
        if (!$cast(coh2_cfg, cfg)) begin
            `uvm_warning("OPC_COH2_SEQ",
                "cfg nao e do tipo uvmt_opc_coh2_cfg_c - usando defaults")
        end

        if (cfg.num_tiles() < 2) begin
            `uvm_warning("OPC_COH2_SEQ",
                "Coerencia requer num_tiles >= 2. Abortando sequencia.")
            return;
        end

        `uvm_info("OPC_COH2_SEQ",
            $sformatf("[INICIO] Padrao=%s | tiles=%0dx%0d | finish_mask=0x%0h",
                pattern.name(), cfg.num_x_tiles, cfg.num_y_tiles, cfg.finish_mask),
            UVM_LOW)

        case (pattern)
            COH2_FALSE_SHARING: begin
                `uvm_info("OPC_COH2_SEQ",
                    "Padrao FALSE_SHARING: tile0 escreve word[0], tile1 escreve word[1] — mesma linha 64B",
                    UVM_LOW)
                `uvm_info("OPC_COH2_SEQ",
                    $sformatf("  Linha de cache: 0x%010h | Tile0: +0x0 | Tile1: +0x8",
                        (coh2_cfg != null) ? coh2_cfg.data_base_addr : 40'h8000_2000),
                    UVM_LOW)
                // O binário (boot.hex) deve implementar este padrão.
                // Esta sequência documenta o padrão esperado e aguarda execução.
            end

            COH2_PRODUCER_CONSUMER: begin
                `uvm_info("OPC_COH2_SEQ",
                    "Padrao PRODUCER_CONSUMER: tile0 escreve, tile1 le — verifica coerencia ponto-a-ponto",
                    UVM_LOW)
            end

            COH2_PING_PONG: begin
                `uvm_info("OPC_COH2_SEQ",
                    "Padrao PING_PONG: tiles alternam escritas na mesma linha — máximo de invalidações",
                    UVM_LOW)
            end

            COH2_MULTI_LINE: begin
                `uvm_info("OPC_COH2_SEQ",
                    "Padrao MULTI_LINE: cada tile escreve em 2 linhas — mede tráfego de coerência total",
                    UVM_LOW)
            end
        endcase

        `uvm_info("OPC_COH2_SEQ",
            "[SEQUENCIA APLICADA] Aguardando conclusao via finish_mask no scoreboard",
            UVM_LOW)
    endtask

endclass : uvmt_opc_coh2_seq_c

`endif // __UVMT_OPC_COH2_SEQ_SV__
