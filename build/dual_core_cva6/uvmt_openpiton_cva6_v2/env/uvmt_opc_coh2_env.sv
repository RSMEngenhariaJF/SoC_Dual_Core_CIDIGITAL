// ============================================================================
// uvmt_opc_coh2_env.sv
// Ambiente UVM v2 de coerência.
//
// Melhorias sobre uvmt_opc_env_c:
//   1. Inclui agente sb_mon (uvmt_opc_sb_agent_c) para monitorar
//      commits do store buffer nos dois tiles
//   2. Instancia uvmt_opc_coh2_scoreboard_c (scoreboard aprimorado)
//   3. Conecta saída do sb_mon ao scoreboard v2
//
// NOTA: A correção de config_db (set(null, "*", ...)) é feita no TESTE,
// não aqui, para garantir que a propagação ocorra antes da build dos filhos.
// ============================================================================
`ifndef __UVMT_OPC_COH2_ENV_SV__
`define __UVMT_OPC_COH2_ENV_SV__

class uvmt_opc_coh2_env_c extends uvm_env;

    `uvm_component_utils(uvmt_opc_coh2_env_c)

    // ---- Configuração -------------------------------------------------------
    uvmt_opc_coh2_cfg_c cfg;

    // ---- Agentes padrão (mesmos do v1) --------------------------------------
    uvmt_opc_clk_rst_agent_c  clk_rst_agent;
    uvmt_opc_noc_agent_c      noc_agent;
    uvmt_opc_l15_tri_agent_c  l15_tri_agent;
    uvmt_opc_status_agent_c   status_agent;
    uvmt_opc_uart_agent_c     uart_agent;

    // ---- Agente novo: store buffer monitor ----------------------------------
    uvmt_opc_sb_agent_c       sb_mon_agent;

    // ---- Scoreboard v2 e cobertura ------------------------------------------
    uvmt_opc_coh2_scoreboard_c  scoreboard;
    uvmt_opc_cov_model_c        cov_model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // =========================================================================
    // build_phase
    // =========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Obtém (ou cria) o objeto de configuração v2
        begin
            uvmt_opc_cfg_c base_cfg;
            if (!uvm_config_db #(uvmt_opc_cfg_c)::get(this, "", "cfg", base_cfg)) begin
                cfg = uvmt_opc_coh2_cfg_c::type_id::create("cfg");
                void'(cfg.randomize());
                `uvm_warning("OPC_COH2_ENV",
                    "cfg nao encontrado no config_db — usando configuracao v2 padrao")
            end else begin
                if (!$cast(cfg, base_cfg)) begin
                    // cfg base recebido, cria v2 com os mesmos valores
                    cfg = uvmt_opc_coh2_cfg_c::type_id::create("cfg");
                    cfg.num_x_tiles      = base_cfg.num_x_tiles;
                    cfg.num_y_tiles      = base_cfg.num_y_tiles;
                    cfg.finish_mask      = base_cfg.finish_mask;
                    cfg.clk_period_ps    = base_cfg.clk_period_ps;
                    cfg.rst_cycles       = base_cfg.rst_cycles;
                    cfg.timeout_cycles   = base_cfg.timeout_cycles;
                    cfg.enable_coh_check = base_cfg.enable_coh_check;
                    cfg.enable_coverage  = base_cfg.enable_coverage;
                end
            end
        end

        // Propaga cfg para todos os filhos (inclui seqüencias via wildcard duplo)
        uvm_config_db #(uvmt_opc_cfg_c)::set(this, "*", "cfg", cfg);

        // Cria agentes padrão
        clk_rst_agent = uvmt_opc_clk_rst_agent_c::type_id::create("clk_rst_agent", this);
        noc_agent     = uvmt_opc_noc_agent_c::type_id::create("noc_agent",     this);
        l15_tri_agent = uvmt_opc_l15_tri_agent_c::type_id::create("l15_tri_agent", this);
        status_agent  = uvmt_opc_status_agent_c::type_id::create("status_agent",  this);
        uart_agent    = uvmt_opc_uart_agent_c::type_id::create("uart_agent",    this);

        // Cria agente store buffer (habilitado por padrão)
        if (cfg.enable_sb_mon)
            sb_mon_agent = uvmt_opc_sb_agent_c::type_id::create("sb_mon_agent", this);

        // Cria scoreboard v2 e cobertura
        scoreboard = uvmt_opc_coh2_scoreboard_c::type_id::create("scoreboard", this);
        cov_model  = uvmt_opc_cov_model_c::type_id::create("cov_model",        this);
    endfunction

    // =========================================================================
    // connect_phase
    // =========================================================================
    function void connect_phase(uvm_phase phase);
        // Conexões padrão (mesmo que v1)
        l15_tri_agent.trans_ap.connect(scoreboard.l15_trans_export);
        l15_tri_agent.inval_ap.connect(scoreboard.l15_inval_export);
        noc_agent.coherence_ap.connect(scoreboard.noc_coh_export);
        status_agent.trap_ap.connect(scoreboard.trap_export);
        l15_tri_agent.trans_ap.connect(cov_model.analysis_export);

        // Nova conexão: sb_mon → scoreboard v2
        if (cfg.enable_sb_mon && sb_mon_agent != null)
            sb_mon_agent.ap.connect(scoreboard.sb_commit_export);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info("OPC_COH2_ENV",
            $sformatf("Ambiente V2 iniciado: %0dx%0d tiles | sb_mon=%0b | latencia=%0b | cov=%0b",
                cfg.num_x_tiles, cfg.num_y_tiles,
                cfg.enable_sb_mon,
                cfg.enable_latency_tracking,
                cfg.enable_coverage),
            UVM_LOW)
    endfunction

endclass : uvmt_opc_coh2_env_c

`endif // __UVMT_OPC_COH2_ENV_SV__
