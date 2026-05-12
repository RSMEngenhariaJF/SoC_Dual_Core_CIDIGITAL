// ============================================================================
// uvmt_opc_cov_model.sv
// Modelo de cobertura funcional para OpenPiton+CVA6.
//
// NOTA XSIM: Covergroups embedded em classe NAO podem ser declarados como
// variaveis membro (cg_xxx var;). O XSim instancia automaticamente um
// covergroup embedded por instancia de classe. A amostragem e feita
// chamando diretamente o nome do covergroup: cg_l15_req_types.sample();
// ============================================================================
`ifndef __UVMT_OPC_COV_MODEL_SV__
`define __UVMT_OPC_COV_MODEL_SV__

class uvmt_opc_cov_model_c extends uvm_subscriber #(uvmt_opc_l15_tri_seq_item_c);

    `uvm_component_utils(uvmt_opc_cov_model_c)

    uvmt_opc_cfg_c cfg;

    // Handles para os itens mais recentes (atualizados antes de sample())
    protected uvmt_opc_l15_tri_seq_item_c cur_l15;
    protected uvmt_opc_noc_seq_item_c     cur_noc;

    // =========================================================================
    // Covergroups embedded - NAO declarar instancias; XSim cria automaticamente
    // =========================================================================

    // ---- Tipos de transacao L1.5 + cacheable x NC ----------------------------
    covergroup cg_l15_req_types;
        cp_req_type: coverpoint cur_l15.req_type {
            bins load  = {L15_REQ_LOAD};
            bins store = {L15_REQ_STORE};
            bins ifill = {L15_REQ_IFILL};
            bins amo   = {L15_REQ_AMO};
            bins flush = {L15_REQ_FLUSH};
        }
        cp_nc: coverpoint cur_l15.is_nc {
            bins cacheable     = {1'b0};
            bins non_cacheable = {1'b1};
        }
        cx_type_nc: cross cp_req_type, cp_nc;
    endgroup

    // ---- Operacoes AMO individuais ------------------------------------------
    covergroup cg_amo_ops;
        cp_amo_op: coverpoint cur_l15.amo_op {
            bins amo_swap = {4'h0};
            bins amo_add  = {4'h1};
            bins amo_and  = {4'h3};
            bins amo_or   = {4'h5};
            bins amo_xor  = {4'h7};
            bins amo_max  = {4'h9};
            bins amo_maxu = {4'hB};
            bins amo_min  = {4'hD};
            bins amo_minu = {4'hF};
        }
    endgroup

    // ---- Tipos de mensagem NoC (3 redes) ------------------------------------
    covergroup cg_noc_msg_types;
        cp_net: coverpoint cur_noc.network {
            bins noc1 = {NOC_NETWORK_1};
            bins noc2 = {NOC_NETWORK_2};
            bins noc3 = {NOC_NETWORK_3};
        }
        cp_msg: coverpoint cur_noc.msg_type {
            bins load_req  = {NOC_MSG_LOAD_REQ};
            bins store_req = {NOC_MSG_STORE_REQ};
            bins ifill_req = {NOC_MSG_IFILL_REQ};
            bins amo_req   = {NOC_MSG_AMO_REQ};
            bins load_ret  = {NOC_MSG_LOAD_RET};
            bins st_ack    = {NOC_MSG_ST_ACK};
            bins ifill_ret = {NOC_MSG_IFILL_RET};
            bins amo_ret   = {NOC_MSG_AMO_RET};
            bins inval_req = {NOC_MSG_INVAL_REQ};
            bins inval_ack = {NOC_MSG_INVAL_ACK};
        }
    endgroup

    // ---- Transicoes MESI via tipo de mensagem NoC ---------------------------
    covergroup cg_mesi_transitions;
        cp_transition: coverpoint cur_noc.msg_type {
            bins inval  = {NOC_MSG_INVAL_REQ};
            bins shared = {NOC_MSG_LOAD_RET};
            bins mod    = {NOC_MSG_ST_ACK};
            bins amo    = {NOC_MSG_AMO_RET};
        }
    endgroup

    // ---- Faixas de latencia de acesso L1.5 ----------------------------------
    covergroup cg_l15_latency;
        cp_lat_cycles: coverpoint (cur_l15.latency_ps() / 10000) {
            bins lat_0_1  = {[0:1]};
            bins lat_2_4  = {[2:4]};
            bins lat_5_20 = {[5:20]};
            bins lat_gt20 = {[21:$]};
        }
    endgroup

    // =========================================================================

    function new(string name, uvm_component parent);
        super.new(name, parent);
        // Inicializa handles com objetos dummy para evitar null pointer
        cur_l15 = null;
        cur_noc = null;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uvmt_opc_cfg_c)::get(this, "", "cfg", cfg))
            `uvm_fatal("OPC_COV", "cfg nao encontrado no config_db")
    endfunction

    // Chamado automaticamente quando um item L1.5 e publicado
    function void write(uvmt_opc_l15_tri_seq_item_c t);
        if (!cfg.enable_coverage) return;
        if (t == null) return;
        cur_l15 = t;
        cg_l15_req_types.sample();
        cg_l15_latency.sample();
        if (cur_l15.req_type == L15_REQ_AMO)
            cg_amo_ops.sample();
    endfunction

    // Chamado pelo ambiente para amostrar eventos NoC
    function void write_noc(uvmt_opc_noc_seq_item_c t);
        if (!cfg.enable_coverage) return;
        if (t == null) return;
        cur_noc = t;
        cg_noc_msg_types.sample();
        if (t.is_coherence_msg)
            cg_mesi_transitions.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        if (!cfg.enable_coverage) return;
        `uvm_info("OPC_COV",
            $sformatf("Cobertura: L15_req=%.1f%% NoC=%.1f%% AMO=%.1f%% MESI=%.1f%%",
                cg_l15_req_types.get_coverage(),
                cg_noc_msg_types.get_coverage(),
                cg_amo_ops.get_coverage(),
                cg_mesi_transitions.get_coverage()),
            UVM_NONE)
    endfunction

endclass : uvmt_opc_cov_model_c

`endif // __UVMT_OPC_COV_MODEL_SV__
