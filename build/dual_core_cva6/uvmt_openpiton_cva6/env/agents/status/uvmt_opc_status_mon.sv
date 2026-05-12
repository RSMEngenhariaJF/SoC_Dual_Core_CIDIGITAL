// ============================================================================
// uvmt_opc_status_mon.sv
// Monitor de status: detecta GOOD_TRAP, BAD_TRAP e saida UART.
// Porta o comportamento dos monitors fake_uart e good_trap/bad_trap
// do piton/verif/env/manycore/ para UVM.
// ============================================================================
`ifndef __UVMT_OPC_STATUS_MON_SV__
`define __UVMT_OPC_STATUS_MON_SV__

class uvmt_opc_status_mon_c extends uvm_monitor;

    `uvm_component_utils(uvmt_opc_status_mon_c)

    virtual uvmt_opc_status_if vif;
    uvmt_opc_cfg_c cfg;

    uvm_analysis_port #(uvmt_opc_status_seq_item_c) trap_ap;  // good/bad trap
    uvm_analysis_port #(uvmt_opc_status_seq_item_c) uart_ap;  // caracteres UART

    // Mascara de tiles ja completados (good_trap ou bad_trap)
    protected longint unsigned completed_mask;
    // Buffer de saida UART (linha completa acumulada)
    protected string uart_line_buf;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        completed_mask = 0;
        uart_line_buf  = "";
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        trap_ap = new("trap_ap", this);
        uart_ap = new("uart_ap", this);

        if (!uvm_config_db #(virtual uvmt_opc_status_if)::get(
                this, "", "status_vif", vif))
            `uvm_fatal("OPC_STATUS_MON", "status_vif nao encontrado no config_db")
        if (!uvm_config_db #(uvmt_opc_cfg_c)::get(
                this, "", "cfg", cfg))
            `uvm_fatal("OPC_STATUS_MON", "cfg nao encontrado no config_db")
    endfunction

    task run_phase(uvm_phase phase);
        @(posedge vif.clk iff vif.rst_n === 1'b1);
        `uvm_info("OPC_STATUS_MON", "Monitor de status iniciado", UVM_LOW)
        fork
            monitor_traps();
            monitor_uart();
        join
    endtask

    // ---- Detecta good_trap / bad_trap por tile ------------------------------
    task automatic monitor_traps();
        uvmt_opc_status_seq_item_c item;
        int unsigned nt;

        nt = cfg.num_tiles();

        forever begin
            @(vif.mon_cb);

            for (int t = 0; t < nt; t++) begin
                // Evita publicar evento duplicado para o mesmo tile
                if (completed_mask[t]) continue;

                // GOOD TRAP
                if (vif.mon_cb.good_trap[t] === 1'b1) begin
                    completed_mask[t] = 1;
                    item = uvmt_opc_status_seq_item_c::type_id
                                ::create($sformatf("good_trap_t%0d", t));
                    item.event_type = OPC_EV_GOOD_TRAP;
                    item.tile_id    = t;
                    item.cycle      = vif.mon_cb.cycle_count;
                    trap_ap.write(item);
                    `uvm_info("OPC_STATUS_MON",
                        $sformatf(">>> HIT GOOD TRAP - Tile %0d (ciclo %0d) <<<",
                            t, item.cycle),
                        UVM_NONE)
                end

                // BAD TRAP
                if (vif.mon_cb.bad_trap[t] === 1'b1) begin
                    completed_mask[t] = 1;
                    item = uvmt_opc_status_seq_item_c::type_id
                                ::create($sformatf("bad_trap_t%0d", t));
                    item.event_type = OPC_EV_BAD_TRAP;
                    item.tile_id    = t;
                    item.error_code = vif.mon_cb.bad_trap_code[t];
                    item.cycle      = vif.mon_cb.cycle_count;
                    trap_ap.write(item);
                    `uvm_error("OPC_STATUS_MON",
                        $sformatf(">>> HIT BAD TRAP - Tile %0d code=0x%016h (ciclo %0d) <<<",
                            t, item.error_code, item.cycle))
                end
            end
        end
    endtask

    // ---- Captura saida da UART virtual (fake_uart) -------------------------
    task automatic monitor_uart();
        uvmt_opc_status_seq_item_c item;
        byte ch;

        forever begin
            @(vif.mon_cb iff vif.mon_cb.uart_valid === 1'b1);

            ch = byte'(vif.mon_cb.uart_data);

            item = uvmt_opc_status_seq_item_c::type_id::create("uart_char");
            item.event_type = OPC_EV_UART_CHAR;
            item.uart_char  = vif.mon_cb.uart_data;
            item.cycle      = vif.mon_cb.cycle_count;
            uart_ap.write(item);

            // Acumula linha para display (imprime ao encontrar \n)
            if (ch == 8'h0A) begin  // newline
                `uvm_info("OPC_UART", uart_line_buf, UVM_NONE)
                uart_line_buf = "";
            end else begin
                uart_line_buf = {uart_line_buf, string'(ch)};
            end
        end
    endtask

    // Flush do buffer UART no final
    function void report_phase(uvm_phase phase);
        if (uart_line_buf.len() > 0)
            `uvm_info("OPC_UART", uart_line_buf, UVM_NONE)
        `uvm_info("OPC_STATUS_MON",
            $sformatf("Tiles completados: 0x%0h / esperados: 0x%0h",
                completed_mask, cfg.finish_mask),
            UVM_LOW)
    endfunction

endclass : uvmt_opc_status_mon_c

`endif // __UVMT_OPC_STATUS_MON_SV__
