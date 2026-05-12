// ============================================================================
// uvmt_opc_clk_rst_mon.sv
// Monitor passivo: detecta borda de subida do rst_n e publica item.
// ============================================================================
`ifndef __UVMT_OPC_CLK_RST_MON_SV__
`define __UVMT_OPC_CLK_RST_MON_SV__

class uvmt_opc_clk_rst_mon_c extends uvm_monitor;

    `uvm_component_utils(uvmt_opc_clk_rst_mon_c)

    virtual uvmt_opc_clk_rst_if vif;
    uvm_analysis_port #(uvmt_opc_clk_rst_seq_item_c) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual uvmt_opc_clk_rst_if)::get(
                this, "", "clk_rst_vif", vif))
            `uvm_fatal("OPC_CLK_MON", "clk_rst_vif nao encontrado no config_db")
    endfunction

    task run_phase(uvm_phase phase);
        uvmt_opc_clk_rst_seq_item_c item;

        // Aguarda rst_n subir (primeira borda de subida apos reset)
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        item = uvmt_opc_clk_rst_seq_item_c::type_id::create("clk_rst_obs");
        ap.write(item);
        `uvm_info("OPC_CLK_MON", "Reset desassertado - DUT pronto", UVM_LOW)
    endtask

endclass : uvmt_opc_clk_rst_mon_c

`endif // __UVMT_OPC_CLK_RST_MON_SV__
