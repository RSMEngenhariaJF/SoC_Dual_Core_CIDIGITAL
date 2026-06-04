// ============================================================================
// uvmt_opc_sb_agent.sv
// Agente passivo do store buffer — contém apenas o monitor.
// Não possui driver (monitoramento unidirecional).
// ============================================================================
`ifndef __UVMT_OPC_SB_AGENT_SV__
`define __UVMT_OPC_SB_AGENT_SV__

class uvmt_opc_sb_agent_c extends uvm_agent;

    `uvm_component_utils(uvmt_opc_sb_agent_c)

    uvmt_opc_sb_mon_c  mon;
    uvm_analysis_port #(uvmt_opc_sb_seq_item_c) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap  = new("ap",  this);
        mon = uvmt_opc_sb_mon_c::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        mon.ap.connect(ap);
    endfunction

endclass : uvmt_opc_sb_agent_c

`endif // __UVMT_OPC_SB_AGENT_SV__
