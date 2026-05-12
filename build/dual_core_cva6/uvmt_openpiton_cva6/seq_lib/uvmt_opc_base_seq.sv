// ============================================================================
// uvmt_opc_base_seq.sv
// Sequencia base: configura clock/reset e aguarda DUT pronto.
// Todas as demais sequencias herdam desta.
// ============================================================================
`ifndef __UVMT_OPC_BASE_SEQ_SV__
`define __UVMT_OPC_BASE_SEQ_SV__

class uvmt_opc_base_seq_c extends uvm_sequence #(uvmt_opc_clk_rst_seq_item_c);

    `uvm_object_utils(uvmt_opc_base_seq_c)

    uvmt_opc_cfg_c cfg;

    function new(string name = "uvmt_opc_base_seq");
        super.new(name);
    endfunction

    task pre_start();
        if (!uvm_config_db #(uvmt_opc_cfg_c)::get(
                null, get_full_name(), "cfg", cfg))
            `uvm_fatal("OPC_BASE_SEQ", "cfg nao encontrado no config_db")
    endtask

    // Envia configuracao de clock/reset para o driver
    task send_clk_rst();
        uvmt_opc_clk_rst_seq_item_c item;
        item = uvmt_opc_clk_rst_seq_item_c::type_id::create("clk_cfg");
        start_item(item);
        item.clk_period_ps = cfg.clk_period_ps;
        item.rst_cycles    = cfg.rst_cycles;
        finish_item(item);
    endtask

    task body();
        send_clk_rst();
    endtask

endclass : uvmt_opc_base_seq_c

`endif // __UVMT_OPC_BASE_SEQ_SV__
