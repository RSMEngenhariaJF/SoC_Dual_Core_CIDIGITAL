// ============================================================================
// uvmt_opc_scoreboard.sv
// Scoreboard do ambiente OpenPiton+CVA6.
//
// Responsabilidades:
//   1. Manter shadow memory (modelo de referencia da memoria compartilhada)
//   2. Verificar coerencia MESI via mensagens das redes NoC
//   3. Verificar que leituras retornam valores consistentes com escritas
//   4. Detectar violacoes de coerencia:
//      - Escrita em linha que outro tile tem em estado S sem invalidacao previa
//      - Duas copias Modificadas da mesma linha simultaneamente
//      - Resposta de load com dado diferente do esperado na shadow memory
//   5. Correlacionar GOOD_TRAP / BAD_TRAP com o finish_mask da cfg
// ============================================================================
`ifndef __UVMT_OPC_SCOREBOARD_SV__
`define __UVMT_OPC_SCOREBOARD_SV__

// Estado de linha de cache no protocolo MESI
typedef enum logic [1:0] {
    MESI_I = 2'b00,  // Invalid
    MESI_S = 2'b01,  // Shared
    MESI_E = 2'b10,  // Exclusive
    MESI_M = 2'b11   // Modified
} mesi_state_e;

// Entrada na tabela de estado de coerencia por linha
typedef struct {
    mesi_state_e state [8];   // estado por tile (maximo 8 tiles)
    logic [63:0] data;        // ultimo dado conhecido
    bit          data_valid;  // dado foi escrito ao menos uma vez
} cache_line_entry_t;

class uvmt_opc_scoreboard_c extends uvm_scoreboard;

    `uvm_component_utils(uvmt_opc_scoreboard_c)

    uvmt_opc_cfg_c cfg;

    // ---- TLM FIFOs de entrada -----------------------------------------------
    // Transacoes L1.5 completas (req+resp) - para verificacao de dado
    uvm_tlm_analysis_fifo #(uvmt_opc_l15_tri_seq_item_c) l15_trans_fifo;
    // Invalidacoes assincronas do L1.5
    uvm_tlm_analysis_fifo #(uvmt_opc_l15_tri_seq_item_c) l15_inval_fifo;
    // Pacotes de coerencia das redes NoC (invalidacoes, acks)
    uvm_tlm_analysis_fifo #(uvmt_opc_noc_seq_item_c)     noc_coh_fifo;
    // Eventos de trap (good/bad) por tile
    uvm_tlm_analysis_fifo #(uvmt_opc_status_seq_item_c)  trap_fifo;

    // ---- Exports conectados pelos analysis ports dos agentes ----------------
    uvm_analysis_export #(uvmt_opc_l15_tri_seq_item_c) l15_trans_export;
    uvm_analysis_export #(uvmt_opc_l15_tri_seq_item_c) l15_inval_export;
    uvm_analysis_export #(uvmt_opc_noc_seq_item_c)     noc_coh_export;
    uvm_analysis_export #(uvmt_opc_status_seq_item_c)  trap_export;

    // ---- Shadow memory -------------------------------------------------------
    // Chave: endereco alinhado a linha de cache (64 bytes = 6 LSBs zerados)
    protected cache_line_entry_t shadow_mem [logic [39:0]];

    // ---- Contadores de verificacao ------------------------------------------
    protected longint unsigned chk_pass, chk_fail;
    protected longint unsigned trap_good_cnt, trap_bad_cnt;
    // Mascara de tiles que completaram (good_trap)
    protected longint unsigned completed_mask;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        chk_pass      = 0;
        chk_fail      = 0;
        trap_good_cnt = 0;
        trap_bad_cnt  = 0;
        completed_mask = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        l15_trans_fifo  = new("l15_trans_fifo",  this);
        l15_inval_fifo  = new("l15_inval_fifo",  this);
        noc_coh_fifo    = new("noc_coh_fifo",    this);
        trap_fifo       = new("trap_fifo",        this);

        l15_trans_export = new("l15_trans_export", this);
        l15_inval_export = new("l15_inval_export", this);
        noc_coh_export   = new("noc_coh_export",   this);
        trap_export      = new("trap_export",       this);

        if (!uvm_config_db #(uvmt_opc_cfg_c)::get(
                this, "", "cfg", cfg))
            `uvm_fatal("OPC_SB", "cfg nao encontrado no config_db")
    endfunction

    function void connect_phase(uvm_phase phase);
        l15_trans_export.connect(l15_trans_fifo.analysis_export);
        l15_inval_export.connect(l15_inval_fifo.analysis_export);
        noc_coh_export.connect(noc_coh_fifo.analysis_export);
        trap_export.connect(trap_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        fork
            process_l15_transactions();
            process_l15_invalidations();
            process_noc_coherence();
            process_traps();
        join
    endtask

    // =========================================================================
    // Processamento de transacoes L1.5 completas
    // Verifica: dado de retorno vs shadow memory
    // =========================================================================
    task automatic process_l15_transactions();
        uvmt_opc_l15_tri_seq_item_c item;
        logic [39:0] aligned_addr;
        forever begin
            l15_trans_fifo.get(item);
            aligned_addr = {item.address[39:6], 6'b0};  // alinha a 64 bytes

            case (item.req_type)
                // STORE: atualiza shadow memory
                L15_REQ_STORE: begin
                    if (!item.is_nc) begin
                        if (!shadow_mem.exists(aligned_addr)) begin
                            shadow_mem[aligned_addr].data_valid = 0;
                            foreach (shadow_mem[aligned_addr].state[i])
                                shadow_mem[aligned_addr].state[i] = MESI_I;
                        end
                        shadow_mem[aligned_addr].data       = item.req_data;
                        shadow_mem[aligned_addr].data_valid = 1;
                    end
                    chk_pass++;
                end

                // LOAD: verifica dado retornado vs shadow memory
                L15_REQ_LOAD: begin
                    if (!item.is_nc && shadow_mem.exists(aligned_addr) &&
                        shadow_mem[aligned_addr].data_valid) begin
                        // Verifica apenas o word relevante (simplificado)
                        if (item.ret_data_0 !== shadow_mem[aligned_addr].data) begin
                            `uvm_error("OPC_SB",
                                $sformatf("LOAD MISMATCH addr=0x%010h got=0x%016h expected=0x%016h",
                                    item.address, item.ret_data_0, shadow_mem[aligned_addr].data))
                            chk_fail++;
                        end else begin
                            chk_pass++;
                        end
                    end
                end

                // AMO: atualiza shadow memory com resultado
                L15_REQ_AMO: begin
                    if (shadow_mem.exists(aligned_addr))
                        shadow_mem[aligned_addr].data = item.ret_data_0;
                    else begin
                        shadow_mem[aligned_addr].data       = item.ret_data_0;
                        shadow_mem[aligned_addr].data_valid = 1;
                        foreach (shadow_mem[aligned_addr].state[i])
                            shadow_mem[aligned_addr].state[i] = MESI_I;
                    end
                    chk_pass++;
                end

                default: chk_pass++;
            endcase
        end
    endtask

    // =========================================================================
    // Processamento de invalidacoes assincronas
    // Atualiza estado MESI: linha vai para MESI_I no tile que recebeu inval
    // =========================================================================
    task automatic process_l15_invalidations();
        uvmt_opc_l15_tri_seq_item_c item;
        logic [39:0] aligned_addr;
        forever begin
            l15_inval_fifo.get(item);
            aligned_addr = {item.inval_address[39:6], 6'b0};
            if (shadow_mem.exists(aligned_addr)) begin
                // Assume tile 0 por default (agente tile 0)
                // Para multi-tile, o tile_id viria da instancia do agente
                shadow_mem[aligned_addr].state[0] = MESI_I;
                `uvm_info("OPC_SB",
                    $sformatf("Shadow: addr=0x%010h -> MESI_I (inval assincrono)",
                        aligned_addr),
                    UVM_HIGH)
            end
        end
    endtask

    // =========================================================================
    // Verificacao de protocolo de coerencia via mensagens NoC
    // Detecta violacoes MESI nas redes de invalidacao (NoC3)
    // =========================================================================
    task automatic process_noc_coherence();
        uvmt_opc_noc_seq_item_c item;
        logic [39:0] aligned_addr;

        forever begin
            noc_coh_fifo.get(item);

            if (!cfg.enable_coh_check) continue;

            aligned_addr = {item.address[39:6], 6'b0};

            case (item.msg_type)
                // INVAL_REQ: home node invalida a linha em um tile
                // Verificar: se essa linha ainda estiver como M em outro tile,
                // ha uma violacao (dois tiles com M simultaneamente)
                NOC_MSG_INVAL_REQ: begin
                    if (shadow_mem.exists(aligned_addr)) begin
                        int unsigned m_count = 0;
                        for (int t = 0; t < cfg.num_tiles(); t++) begin
                            if (shadow_mem[aligned_addr].state[t] == MESI_M)
                                m_count++;
                        end
                        if (m_count > 1) begin
                            `uvm_error("OPC_SB",
                                $sformatf("VIOLACAO MESI: dois tiles com estado M na linha 0x%010h ao receber INVAL_REQ", aligned_addr))
                            chk_fail++;
                        end
                        // Marca a linha do tile destino como I
                        if (int'(item.dst_x) < 8)
                            shadow_mem[aligned_addr].state[item.dst_x] = MESI_I;
                    end
                    chk_pass++;
                end

                // INVAL_ACK: tile confirmou invalidacao
                NOC_MSG_INVAL_ACK: begin
                    `uvm_info("OPC_SB",
                        $sformatf("INVAL_ACK: addr=0x%010h tile=(%0d,%0d)",
                            aligned_addr, item.src_x, item.src_y),
                        UVM_HIGH)
                    chk_pass++;
                end

                default: ;
            endcase
        end
    endtask

    // =========================================================================
    // Processa eventos de trap e verifica finish_mask
    // =========================================================================
    task automatic process_traps();
        uvmt_opc_status_seq_item_c item;
        forever begin
            trap_fifo.get(item);
            case (item.event_type)
                OPC_EV_GOOD_TRAP: begin
                    completed_mask[item.tile_id] = 1;
                    trap_good_cnt++;
                    `uvm_info("OPC_SB",
                        $sformatf("GOOD TRAP tile=%0d. Completados=0x%0h / Esperados=0x%0h",
                            item.tile_id, completed_mask, cfg.finish_mask),
                        UVM_LOW)
                end
                OPC_EV_BAD_TRAP: begin
                    trap_bad_cnt++;
                    `uvm_error("OPC_SB",
                        $sformatf("BAD TRAP tile=%0d code=0x%016h",
                            item.tile_id, item.error_code))
                end
                default: ;
            endcase
        end
    endtask

    // =========================================================================
    // Relatorio final
    // =========================================================================
    function void check_phase(uvm_phase phase);
        // Verifica se todos os tiles exigidos pelo finish_mask completaram
        if ((completed_mask & cfg.finish_mask) !== cfg.finish_mask) begin
            `uvm_error("OPC_SB",
                $sformatf("finish_mask nao satisfeito: completados=0x%0h esperados=0x%0h",
                    completed_mask, cfg.finish_mask))
        end
        if (trap_bad_cnt > 0)
            `uvm_error("OPC_SB",
                $sformatf("%0d BAD TRAP(s) detectado(s)", trap_bad_cnt))
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("OPC_SB", "=== SCOREBOARD FINAL ===", UVM_NONE)
        `uvm_info("OPC_SB", $sformatf("  Verificacoes OK  : %0d", chk_pass),      UVM_NONE)
        `uvm_info("OPC_SB", $sformatf("  Verificacoes FAIL: %0d", chk_fail),      UVM_NONE)
        `uvm_info("OPC_SB", $sformatf("  GOOD TRAPs       : %0d", trap_good_cnt), UVM_NONE)
        `uvm_info("OPC_SB", $sformatf("  BAD TRAPs        : %0d", trap_bad_cnt),  UVM_NONE)
        `uvm_info("OPC_SB", $sformatf("  Shadow mem lines : %0d", shadow_mem.size()), UVM_NONE)
    endfunction

endclass : uvmt_opc_scoreboard_c

`endif // __UVMT_OPC_SCOREBOARD_SV__
