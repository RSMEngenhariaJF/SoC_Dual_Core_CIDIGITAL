// ============================================================================
// uvmt_opc_clk_rst_seq_item.sv
// ============================================================================
`ifndef __UVMT_OPC_CLK_RST_SEQ_ITEM_SV__
`define __UVMT_OPC_CLK_RST_SEQ_ITEM_SV__

class uvmt_opc_clk_rst_seq_item_c extends uvm_sequence_item;

    `uvm_object_utils_begin(uvmt_opc_clk_rst_seq_item_c)
        `uvm_field_int(clk_period_ps, UVM_ALL_ON)
        `uvm_field_int(rst_cycles,    UVM_ALL_ON)
    `uvm_object_utils_end

    rand int unsigned clk_period_ps;  // periodo do clock em picosegundos
    rand int unsigned rst_cycles;     // ciclos com rst_n=0

    constraint c_clk { clk_period_ps inside {[5_000:100_000]}; }  // 10-200 MHz
    constraint c_rst { rst_cycles    inside {[5:100]};           }

    function new(string name = "uvmt_opc_clk_rst_seq_item");
        super.new(name);
        clk_period_ps = 10_000;
        rst_cycles    = 20;
    endfunction

endclass : uvmt_opc_clk_rst_seq_item_c

`endif // __UVMT_OPC_CLK_RST_SEQ_ITEM_SV__
