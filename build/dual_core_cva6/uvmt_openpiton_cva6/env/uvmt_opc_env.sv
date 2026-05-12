// ============================================================================
// uvmt_opc_env.sv
// Ambiente UVM top-level do OpenPiton+CVA6.
// Instancia todos os agentes, scoreboard e modelo de cobertura.
// Conecta os analysis ports entre os componentes.
// ============================================================================
`ifndef __UVMT_OPC_ENV_SV__
`define __UVMT_OPC_ENV_SV__

class uvmt_opc_env_c extends uvm_env;

    `uvm_component_utils(uvmt_opc_env_c)

    // ---- Configuracao -------------------------------------------------------
    uvmt_opc_cfg_c cfg;

    // ---- Agentes ------------------------------------------------------------
    uvmt_opc_clk_rst_agent_c  clk_rst_agent;  // ativo: gera clock e reset
    uvmt_opc_noc_agent_c      noc_agent;      // passivo: monitora NoC1/2/3
    uvmt_opc_l15_tri_agent_c  l15_tri_agent;  // passivo: monitora TRI L1.5
    uvmt_opc_status_agent_c   status_agent;   // passivo: good/bad trap + UART
    uvmt_opc_uart_agent_c     uart_agent;     // passivo: caracteres UART

    // ---- Scoreboard e Cobertura ---------------------------------------------
    uvmt_opc_scoreboard_c   scoreboard;
    uvmt_opc_cov_model_c    cov_model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // =========================================================================
    // build_phase: cria todos os componentes
    // =========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Recupera (ou cria) o objeto de configuracao
        if (!uvm_config_db #(uvmt_opc_cfg_c)::get(this, "", "cfg", cfg)) begin
            cfg = uvmt_opc_cfg_c::type_id::create("cfg");
            void'(cfg.randomize());
            `uvm_warning("OPC_ENV",
                "cfg nao encontrado no config_db - usando configuracao padrao")
        end

        // Propaga cfg para todos os filhos
        uvm_config_db #(uvmt_opc_cfg_c)::set(this, "*", "cfg", cfg);

        // Cria agentes
        clk_rst_agent = uvmt_opc_clk_rst_agent_c::type_id::create("clk_rst_agent", this);
        noc_agent     = uvmt_opc_noc_agent_c::type_id::create("noc_agent",     this);
        l15_tri_agent = uvmt_opc_l15_tri_agent_c::type_id::create("l15_tri_agent", this);
        status_agent  = uvmt_opc_status_agent_c::type_id::create("status_agent",  this);
        uart_agent    = uvmt_opc_uart_agent_c::type_id::create("uart_agent",    this);

        // Cria scoreboard e cobertura
        scoreboard = uvmt_opc_scoreboard_c::type_id::create("scoreboard", this);
        cov_model  = uvmt_opc_cov_model_c::type_id::create("cov_model",  this);
    endfunction

    // =========================================================================
    // connect_phase: conecta analysis ports
    // =========================================================================
    function void connect_phase(uvm_phase phase);
        // L1.5 TRI -> Scoreboard
        l15_tri_agent.trans_ap.connect(scoreboard.l15_trans_export);
        l15_tri_agent.inval_ap.connect(scoreboard.l15_inval_export);

        // NoC coerencia -> Scoreboard
        noc_agent.coherence_ap.connect(scoreboard.noc_coh_export);

        // Status (trap) -> Scoreboard
        status_agent.trap_ap.connect(scoreboard.trap_export);

        // L1.5 TRI -> Coverage
        l15_tri_agent.trans_ap.connect(cov_model.analysis_export);
    endfunction

    // =========================================================================
    // start_of_simulation_phase: imprime topologia
    // =========================================================================
    function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info("OPC_ENV",
            $sformatf("Ambiente iniciado: %0dx%0d tiles | iss=%0b | coh=%0b | cov=%0b",
                cfg.num_x_tiles, cfg.num_y_tiles,
                1'b0,   // ISS check placeholder
                cfg.enable_coh_check,
                cfg.enable_coverage),
            UVM_LOW)
    endfunction

endclass : uvmt_opc_env_c

`endif // __UVMT_OPC_ENV_SV__
