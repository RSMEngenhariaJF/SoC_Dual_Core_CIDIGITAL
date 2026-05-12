// ============================================================================
// uvmt_opc_uart_mon.sv
// Monitor da UART virtual. Reusa a interface de status (uart_valid/data).
// ============================================================================
`ifndef __UVMT_OPC_UART_MON_SV__
`define __UVMT_OPC_UART_MON_SV__

class uvmt_opc_uart_mon_c extends uvm_monitor;

    `uvm_component_utils(uvmt_opc_uart_mon_c)

    virtual uvmt_opc_status_if vif;
    uvm_analysis_port #(uvmt_opc_uart_seq_item_c) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual uvmt_opc_status_if)::get(
                this, "", "status_vif", vif))
            `uvm_fatal("OPC_UART_MON", "status_vif nao encontrado no config_db")
    endfunction

    task run_phase(uvm_phase phase);
        uvmt_opc_uart_seq_item_c item;
        @(posedge vif.clk iff vif.rst_n === 1'b1);
        forever begin
            @(vif.mon_cb iff vif.mon_cb.uart_valid === 1'b1);
            item = uvmt_opc_uart_seq_item_c::type_id::create("uart_item");
            item.data  = vif.mon_cb.uart_data;
            item.cycle = vif.mon_cb.cycle_count;
            ap.write(item);
        end
    endtask

endclass : uvmt_opc_uart_mon_c

`endif // __UVMT_OPC_UART_MON_SV__
