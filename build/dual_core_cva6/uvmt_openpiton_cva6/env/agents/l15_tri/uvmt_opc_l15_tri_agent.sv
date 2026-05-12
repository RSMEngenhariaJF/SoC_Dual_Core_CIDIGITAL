// ============================================================================
// uvmt_opc_l15_tri_agent.sv
// ============================================================================
`ifndef __UVMT_OPC_L15_TRI_AGENT_SV__
`define __UVMT_OPC_L15_TRI_AGENT_SV__

class uvmt_opc_l15_tri_agent_c extends uvm_agent;

    `uvm_component_utils(uvmt_opc_l15_tri_agent_c)

    uvmt_opc_l15_tri_mon_c mon;

    uvm_analysis_port #(uvmt_opc_l15_tri_seq_item_c) trans_ap;
    uvm_analysis_port #(uvmt_opc_l15_tri_seq_item_c) inval_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        is_active = UVM_PASSIVE;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        trans_ap = new("trans_ap", this);
        inval_ap = new("inval_ap", this);
        mon = uvmt_opc_l15_tri_mon_c::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        mon.trans_ap.connect(trans_ap);
        mon.inval_ap.connect(inval_ap);
    endfunction

endclass : uvmt_opc_l15_tri_agent_c

`endif // __UVMT_OPC_L15_TRI_AGENT_SV__
