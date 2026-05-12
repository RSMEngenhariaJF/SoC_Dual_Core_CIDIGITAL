// ============================================================================
// uvmt_opc_clk_rst_agent.sv
// ============================================================================
`ifndef __UVMT_OPC_CLK_RST_AGENT_SV__
`define __UVMT_OPC_CLK_RST_AGENT_SV__

class uvmt_opc_clk_rst_agent_c extends uvm_agent;

    `uvm_component_utils(uvmt_opc_clk_rst_agent_c)

    uvmt_opc_clk_rst_drv_c drv;
    uvmt_opc_clk_rst_mon_c mon;
    uvm_sequencer #(uvmt_opc_clk_rst_seq_item_c) seqr;

    uvm_analysis_port #(uvmt_opc_clk_rst_seq_item_c) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap   = new("ap", this);
        seqr = uvm_sequencer #(uvmt_opc_clk_rst_seq_item_c)::type_id
                    ::create("seqr", this);
        drv  = uvmt_opc_clk_rst_drv_c::type_id::create("drv", this);
        mon  = uvmt_opc_clk_rst_mon_c::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        mon.ap.connect(ap);
    endfunction

endclass : uvmt_opc_clk_rst_agent_c

`endif // __UVMT_OPC_CLK_RST_AGENT_SV__
