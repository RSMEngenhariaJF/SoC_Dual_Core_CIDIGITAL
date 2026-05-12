// ============================================================================
// uvmt_opc_status_agent.sv
// ============================================================================
`ifndef __UVMT_OPC_STATUS_AGENT_SV__
`define __UVMT_OPC_STATUS_AGENT_SV__

class uvmt_opc_status_agent_c extends uvm_agent;

    `uvm_component_utils(uvmt_opc_status_agent_c)

    uvmt_opc_status_mon_c mon;

    uvm_analysis_port #(uvmt_opc_status_seq_item_c) trap_ap;
    uvm_analysis_port #(uvmt_opc_status_seq_item_c) uart_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        is_active = UVM_PASSIVE;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        trap_ap = new("trap_ap", this);
        uart_ap = new("uart_ap", this);
        mon = uvmt_opc_status_mon_c::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        mon.trap_ap.connect(trap_ap);
        mon.uart_ap.connect(uart_ap);
    endfunction

endclass : uvmt_opc_status_agent_c

`endif // __UVMT_OPC_STATUS_AGENT_SV__
