// ============================================================================
// uvmt_opc_noc_agent.sv
// Agente passivo para as tres redes NoC.
// ============================================================================
`ifndef __UVMT_OPC_NOC_AGENT_SV__
`define __UVMT_OPC_NOC_AGENT_SV__

class uvmt_opc_noc_agent_c extends uvm_agent;

    `uvm_component_utils(uvmt_opc_noc_agent_c)

    uvmt_opc_noc_mon_c mon;

    uvm_analysis_port #(uvmt_opc_noc_seq_item_c) noc1_ap;
    uvm_analysis_port #(uvmt_opc_noc_seq_item_c) noc2_ap;
    uvm_analysis_port #(uvmt_opc_noc_seq_item_c) noc3_ap;
    uvm_analysis_port #(uvmt_opc_noc_seq_item_c) coherence_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        is_active = UVM_PASSIVE;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        noc1_ap      = new("noc1_ap",      this);
        noc2_ap      = new("noc2_ap",      this);
        noc3_ap      = new("noc3_ap",      this);
        coherence_ap = new("coherence_ap", this);
        mon = uvmt_opc_noc_mon_c::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        mon.noc1_ap.connect(noc1_ap);
        mon.noc2_ap.connect(noc2_ap);
        mon.noc3_ap.connect(noc3_ap);
        mon.coherence_ap.connect(coherence_ap);
    endfunction

endclass : uvmt_opc_noc_agent_c

`endif // __UVMT_OPC_NOC_AGENT_SV__
