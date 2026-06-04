// ============================================================================
// uvmt_opc_coh2_scoreboard.sv
// Scoreboard aprimorado para testbench v2 de coerência.
//
// Melhorias sobre uvmt_opc_scoreboard_c:
//   1. Contadores de stores por tile (per-hart)
//   2. Contador de INVAL_REQ e INVAL_ACK por tile de destino
//   3. Medição de latência INVAL_REQ → INVAL_ACK (ciclos)
//   4. Detecção de false sharing (dois tiles acessam palavras distintas
//      dentro da mesma linha de cache de 64 bytes)
//   5. Análise do store buffer via analysis port dedicado (sb_mon)
//   6. Verificação de finish_mask por tile individualmente
// ============================================================================
`ifndef __UVMT_OPC_COH2_SCOREBOARD_SV__
`define __UVMT_OPC_COH2_SCOREBOARD_SV__

class uvmt_opc_coh2_scoreboard_c extends uvmt_opc_scoreboard_c;

    `uvm_component_utils(uvmt_opc_coh2_scoreboard_c)

    // ---- Porta de análise do store buffer (nova) ----------------------------
    uvm_tlm_analysis_fifo #(uvmt_opc_sb_seq_item_c) sb_commit_fifo;
    uvm_analysis_export   #(uvmt_opc_sb_seq_item_c) sb_commit_export;

    // ---- Contadores por tile ------------------------------------------------
    protected longint unsigned stores_per_tile [2];     // stores commitados
    protected longint unsigned inval_req_per_tile [2];  // INVAL_REQ recebidos
    protected longint unsigned inval_ack_per_tile [2];  // INVAL_ACK enviados

    // ---- Medição de latência INVAL -----------------------------------------
    // Chave: endereço alinhado → ciclo em que o INVAL_REQ foi emitido
    protected longint unsigned inval_req_cycle [logic [39:0]];
    protected longint unsigned inval_latency_sum;    // soma das latências
    protected longint unsigned inval_latency_count;  // número de pares REQ/ACK
    protected longint unsigned inval_latency_max;    // latência máxima
    protected longint unsigned inval_latency_min;    // latência mínima
    protected longint unsigned current_cycle;        // ciclo atual (do sb_mon)

    // ---- Detecção de false sharing -----------------------------------------
    // false_sharing_accesses[cache_line_addr] = conjunto de tiles que acessaram
    protected bit [7:0] false_sharing_tiles [logic [39:0]];
    protected longint unsigned false_sharing_events;

    // ---- Verificação finish_mask por tile -----------------------------------
    // completed_mask herdado do scoreboard base (via process_traps)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        stores_per_tile    = '{0, 0};
        inval_req_per_tile = '{0, 0};
        inval_ack_per_tile = '{0, 0};
        inval_latency_sum   = 0;
        inval_latency_count = 0;
        inval_latency_max   = 0;
        inval_latency_min   = 64'hFFFF_FFFF_FFFF_FFFF;
        current_cycle       = 0;
        false_sharing_events = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_commit_fifo   = new("sb_commit_fifo",   this);
        sb_commit_export = new("sb_commit_export",  this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sb_commit_export.connect(sb_commit_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        // Roda todos os processos do scoreboard base + novo processo sb_mon
        fork
            process_l15_transactions();
            process_l15_invalidations();
            process_noc_coherence_v2();
            process_traps();
            process_sb_commits();
        join
    endtask

    // =========================================================================
    // Processamento aprimorado de coerência NoC:
    //   - Adiciona contagem INVAL_REQ/ACK por tile
    //   - Mede latência entre REQ e ACK
    //   - Usa current_cycle do sb_mon para timestamps
    // =========================================================================
    task automatic process_noc_coherence_v2();
        uvmt_opc_noc_seq_item_c item;
        logic [39:0] aligned_addr;

        forever begin
            noc_coh_fifo.get(item);

            if (!cfg.enable_coh_check) continue;

            aligned_addr = {item.address[39:6], 6'b0};

            case (item.msg_type)
                NOC_MSG_INVAL_REQ: begin
                    // Contabiliza por tile de destino
                    if (int'(item.dst_x) < 2)
                        inval_req_per_tile[item.dst_x]++;

                    // Registra ciclo do REQ para cálculo de latência
                    inval_req_cycle[aligned_addr] = current_cycle;

                    // Verificação MESI (herdada — dois M simultâneos)
                    if (shadow_mem.exists(aligned_addr)) begin
                        int unsigned m_count = 0;
                        for (int t = 0; t < cfg.num_tiles(); t++) begin
                            if (shadow_mem[aligned_addr].state[t] == MESI_M)
                                m_count++;
                        end
                        if (m_count > 1) begin
                            `uvm_error("OPC_SB_V2",
                                $sformatf("VIOLACAO MESI: 2 tiles com M na linha 0x%010h ao receber INVAL_REQ",
                                    aligned_addr))
                            chk_fail++;
                        end
                        if (int'(item.dst_x) < 8)
                            shadow_mem[aligned_addr].state[item.dst_x] = MESI_I;
                    end
                    chk_pass++;

                    `uvm_info("OPC_SB_V2",
                        $sformatf("INVAL_REQ addr=0x%010h dst_tile=%0d @cyc=%0d",
                            aligned_addr, item.dst_x, current_cycle),
                        UVM_MEDIUM)
                end

                NOC_MSG_INVAL_ACK: begin
                    // Contabiliza por tile de origem
                    if (int'(item.src_x) < 2)
                        inval_ack_per_tile[item.src_x]++;

                    // Calcula latência se há REQ pendente
                    if (inval_req_cycle.exists(aligned_addr)) begin
                        longint unsigned lat;
                        lat = current_cycle - inval_req_cycle[aligned_addr];
                        inval_req_cycle.delete(aligned_addr);
                        inval_latency_sum   += lat;
                        inval_latency_count++;
                        if (lat > inval_latency_max) inval_latency_max = lat;
                        if (lat < inval_latency_min) inval_latency_min = lat;
                        `uvm_info("OPC_SB_V2",
                            $sformatf("INVAL_ACK addr=0x%010h src_tile=%0d latencia=%0d ciclos",
                                aligned_addr, item.src_x, lat),
                            UVM_MEDIUM)
                    end
                    chk_pass++;
                end

                default: ;
            endcase
        end
    endtask

    // =========================================================================
    // Processamento de commits do store buffer:
    //   - Atualiza current_cycle para timestamps de latência
    //   - Contabiliza stores por tile
    //   - Detecta false sharing (dois tiles escrevem na mesma linha de cache)
    // =========================================================================
    task automatic process_sb_commits();
        uvmt_opc_sb_seq_item_c item;
        logic [39:0] aligned_addr;

        forever begin
            sb_commit_fifo.get(item);
            current_cycle = item.cycle_count;
            aligned_addr  = {item.address[39:6], 6'b0};

            // Contagem por tile
            if (item.tile_id < 2)
                stores_per_tile[item.tile_id]++;

            // Detecção de false sharing:
            // Linha acessada por mais de 1 tile com endereços diferentes dentro da linha
            if (false_sharing_tiles.exists(aligned_addr)) begin
                bit tile_bit = 1 << item.tile_id;
                if ((false_sharing_tiles[aligned_addr] & tile_bit) == 0) begin
                    // Outro tile já acessou esta linha — é false sharing!
                    false_sharing_events++;
                    `uvm_info("OPC_SB_V2",
                        $sformatf("FALSE_SHARING detectado: linha=0x%010h tile=%0d addr=0x%014h tiles_anteriores=%0b",
                            aligned_addr, item.tile_id, item.address,
                            false_sharing_tiles[aligned_addr]),
                        UVM_LOW)
                end
                false_sharing_tiles[aligned_addr] |= (1 << item.tile_id);
            end else begin
                false_sharing_tiles[aligned_addr] = (1 << item.tile_id);
            end

            `uvm_info("OPC_SB_V2", item.convert2string(), UVM_HIGH)
        end
    endtask

    // =========================================================================
    // check_phase: inclui verificações adicionais v2
    // =========================================================================
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);

        // Verifica se cada tile individualmente completou (finish_mask por bit)
        for (int t = 0; t < cfg.num_tiles(); t++) begin
            if ((cfg.finish_mask >> t) & 1'b1) begin
                if (!((completed_mask >> t) & 1'b1)) begin
                    `uvm_error("OPC_SB_V2",
                        $sformatf("Tile %0d nao completou (finish_mask bit %0d nao satisfeito)",
                            t, t))
                end
            end
        end

        // Avisa se INVAL_REQs sem ACK correspondente ficaram pendentes
        if (inval_req_cycle.size() > 0) begin
            `uvm_warning("OPC_SB_V2",
                $sformatf("%0d INVAL_REQ(s) sem ACK correspondente ao fim da simulacao",
                    inval_req_cycle.size()))
        end
    endfunction

    // =========================================================================
    // report_phase: relatório completo v2
    // =========================================================================
    function void report_phase(uvm_phase phase);
        // Relatório base
        super.report_phase(phase);

        // Relatório adicional v2
        `uvm_info("OPC_SB_V2", "=== SCOREBOARD V2 - METRICAS AVANCADAS ===", UVM_NONE)

        // Stores por tile
        `uvm_info("OPC_SB_V2",
            $sformatf("  Stores por tile:  tile0=%0d  tile1=%0d",
                stores_per_tile[0], stores_per_tile[1]),
            UVM_NONE)

        // INVAL por tile
        `uvm_info("OPC_SB_V2",
            $sformatf("  INVAL_REQ: tile0=%0d  tile1=%0d",
                inval_req_per_tile[0], inval_req_per_tile[1]),
            UVM_NONE)
        `uvm_info("OPC_SB_V2",
            $sformatf("  INVAL_ACK: tile0=%0d  tile1=%0d",
                inval_ack_per_tile[0], inval_ack_per_tile[1]),
            UVM_NONE)

        // Latência INVAL
        if (inval_latency_count > 0) begin
            `uvm_info("OPC_SB_V2",
                $sformatf("  Latencia INVAL (ciclos): media=%0d min=%0d max=%0d (N=%0d pares)",
                    inval_latency_sum / inval_latency_count,
                    inval_latency_min,
                    inval_latency_max,
                    inval_latency_count),
                UVM_NONE)
        end else begin
            `uvm_info("OPC_SB_V2",
                "  Latencia INVAL: nenhum par REQ/ACK completo observado", UVM_NONE)
        end

        // False sharing
        `uvm_info("OPC_SB_V2",
            $sformatf("  False sharing events: %0d | linhas multi-tile: %0d",
                false_sharing_events, false_sharing_tiles.size()),
            UVM_NONE)

        // Finish mask
        `uvm_info("OPC_SB_V2",
            $sformatf("  Finish mask: esperado=0x%0h completado=0x%0h",
                cfg.finish_mask, completed_mask),
            UVM_NONE)
    endfunction

endclass : uvmt_opc_coh2_scoreboard_c

`endif // __UVMT_OPC_COH2_SCOREBOARD_SV__
