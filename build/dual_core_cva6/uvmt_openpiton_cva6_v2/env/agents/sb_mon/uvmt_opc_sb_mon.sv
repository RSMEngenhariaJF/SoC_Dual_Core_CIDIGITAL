// ============================================================================
// uvmt_opc_sb_mon.sv
// Monitor passivo do store buffer.
//
// Conecta-se ao uvmt_opc_sb_mon_if via virtual interface e emite um
// uvmt_opc_sb_seq_item_c para cada commit de store detectado em qualquer tile.
//
// Publica os itens via analysis port para consumo pelo scoreboard v2.
// ============================================================================
`ifndef __UVMT_OPC_SB_MON_SV__
`define __UVMT_OPC_SB_MON_SV__

class uvmt_opc_sb_mon_c extends uvm_monitor;

    `uvm_component_utils(uvmt_opc_sb_mon_c)

    virtual uvmt_opc_sb_mon_if  vif;
    uvm_analysis_port #(uvmt_opc_sb_seq_item_c) ap;

    longint unsigned cycle_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cycle_cnt = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual uvmt_opc_sb_mon_if)::get(
                this, "", "sb_mon_vif", vif))
            `uvm_fatal("OPC_SB_MON", "sb_mon_vif nao encontrado no config_db")
    endfunction

    task run_phase(uvm_phase phase);
        fork
            count_cycles();
            monitor_tile(0);
            monitor_tile(1);
        join
    endtask

    task automatic count_cycles();
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n)
                cycle_cnt++;
        end
    endtask

    task automatic monitor_tile(int unsigned tile_id);
        uvmt_opc_sb_seq_item_c item;
        forever begin
            @(vif.sb_cb);
            if (!vif.rst_n) continue;

            if (tile_id == 0 && vif.sb_cb.sb0_commit) begin
                item = uvmt_opc_sb_seq_item_c::type_id::create("sb_item");
                item.tile_id     = 0;
                item.address     = vif.sb_cb.sb0_addr;
                item.data        = vif.sb_cb.sb0_data;
                item.cycle_count = cycle_cnt;
                `uvm_info("OPC_SB_MON", item.convert2string(), UVM_HIGH)
                ap.write(item);
            end

            if (tile_id == 1 && vif.sb_cb.sb1_commit) begin
                item = uvmt_opc_sb_seq_item_c::type_id::create("sb_item");
                item.tile_id     = 1;
                item.address     = vif.sb_cb.sb1_addr;
                item.data        = vif.sb_cb.sb1_data;
                item.cycle_count = cycle_cnt;
                `uvm_info("OPC_SB_MON", item.convert2string(), UVM_HIGH)
                ap.write(item);
            end
        end
    endtask

endclass : uvmt_opc_sb_mon_c

`endif // __UVMT_OPC_SB_MON_SV__
