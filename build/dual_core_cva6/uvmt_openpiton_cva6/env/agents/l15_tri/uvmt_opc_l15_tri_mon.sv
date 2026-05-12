// ============================================================================
// uvmt_opc_l15_tri_mon.sv
// Monitor passivo da interface L1.5 TRI.
// Rastreia o ciclo request->response e publicita transacoes completas.
// Porta o comportamento do l15_mon Verilog do piton/verif/env/manycore/.
// ============================================================================
`ifndef __UVMT_OPC_L15_TRI_MON_SV__
`define __UVMT_OPC_L15_TRI_MON_SV__

class uvmt_opc_l15_tri_mon_c extends uvm_monitor;

    `uvm_component_utils(uvmt_opc_l15_tri_mon_c)

    virtual uvmt_opc_l15_tri_if vif;
    uvmt_opc_cfg_c cfg;

    uvm_analysis_port #(uvmt_opc_l15_tri_seq_item_c) trans_ap;  // transacoes completas
    uvm_analysis_port #(uvmt_opc_l15_tri_seq_item_c) inval_ap;  // invalidacoes assincronas

    // Fila FIFO para matching req->resp
    protected uvmt_opc_l15_tri_seq_item_c pending_q[$];

    // Contadores por tipo
    protected longint unsigned cnt_load, cnt_store, cnt_ifill,
                                cnt_amo, cnt_flush, cnt_inval;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cnt_load  = 0;
        cnt_store = 0;
        cnt_ifill = 0;
        cnt_amo   = 0;
        cnt_flush = 0;
        cnt_inval = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        trans_ap = new("trans_ap", this);
        inval_ap = new("inval_ap", this);

        if (!uvm_config_db #(virtual uvmt_opc_l15_tri_if)::get(
                this, "", "l15_tri_vif", vif))
            `uvm_fatal("OPC_L15_MON", "l15_tri_vif nao encontrado no config_db")
        if (!uvm_config_db #(uvmt_opc_cfg_c)::get(
                this, "", "cfg", cfg))
            `uvm_fatal("OPC_L15_MON", "cfg nao encontrado no config_db")
    endfunction

    task run_phase(uvm_phase phase);
        @(posedge vif.clk iff vif.rst_n === 1'b1);
        `uvm_info("OPC_L15_MON", "Monitor L1.5 TRI iniciado", UVM_LOW)
        fork
            mon_requests();
            mon_responses();
            mon_invalidations();
        join
    endtask

    // ---- Monitora requisicoes CVA6 -> L1.5 ----------------------------------
    task automatic mon_requests();
        uvmt_opc_l15_tri_seq_item_c item;
        forever begin
            // Handshake: val=1 e ack=1 no mesmo ciclo = requisicao aceita
            @(vif.mon_cb iff (vif.mon_cb.transducer_l15_val === 1'b1 &&
                              vif.mon_cb.transducer_l15_ack  === 1'b1));

            item = uvmt_opc_l15_tri_seq_item_c::type_id::create("l15_req");
            item.req_type    = opc_l15_req_type_e'(vif.mon_cb.transducer_l15_reqtype);
            item.address     = vif.mon_cb.transducer_l15_address;
            item.req_data    = vif.mon_cb.transducer_l15_data;
            item.is_nc       = vif.mon_cb.transducer_l15_nc;
            item.amo_op      = vif.mon_cb.transducer_l15_amo_op;
            item.req_time_ps = $time;

            `uvm_info("OPC_L15_MON",
                $sformatf("[t=%0t] REQ: %s addr=0x%010h nc=%0b",
                    $time, item.req_type.name(), item.address, item.is_nc),
                UVM_HIGH)

            // Acumular contadores
            case (item.req_type)
                L15_REQ_LOAD:  cnt_load++;
                L15_REQ_STORE: cnt_store++;
                L15_REQ_IFILL: cnt_ifill++;
                L15_REQ_AMO:   cnt_amo++;
                L15_REQ_FLUSH: cnt_flush++;
                default: ;
            endcase

            pending_q.push_back(item);
        end
    endtask

    // ---- Monitora respostas L1.5 -> CVA6 ------------------------------------
    task automatic mon_responses();
        uvmt_opc_l15_tri_seq_item_c item;
        forever begin
            @(vif.mon_cb iff (vif.mon_cb.l15_transducer_val === 1'b1 &&
                              vif.mon_cb.l15_transducer_ack  === 1'b1));

            if (pending_q.size() > 0) begin
                item = pending_q.pop_front();
            end else begin
                `uvm_warning("OPC_L15_MON",
                    "Resposta L1.5 sem requisicao pendente correspondente")
                item = uvmt_opc_l15_tri_seq_item_c::type_id::create("l15_rsp_orphan");
            end

            item.ret_type   = opc_l15_ret_type_e'(vif.mon_cb.l15_transducer_returntype);
            item.ret_data_0 = vif.mon_cb.l15_transducer_returndata_0;
            item.ret_data_1 = vif.mon_cb.l15_transducer_returndata_1;
            item.ret_time_ps = $time;

            `uvm_info("OPC_L15_MON",
                $sformatf("[t=%0t] RSP: %s data0=0x%016h lat=%0d ps",
                    $time, item.ret_type.name(), item.ret_data_0, item.latency_ps()),
                UVM_HIGH)

            trans_ap.write(item);  // transacao completa (req + resp)
        end
    endtask

    // ---- Monitora invalidacoes assincronas L1.5 -> CVA6 --------------------
    task automatic mon_invalidations();
        uvmt_opc_l15_tri_seq_item_c item;
        forever begin
            @(vif.mon_cb iff vif.mon_cb.l15_transducer_inval_valid === 1'b1);

            item = uvmt_opc_l15_tri_seq_item_c::type_id::create("l15_inval");
            item.is_inval      = 1;
            item.inval_address = vif.mon_cb.l15_transducer_inval_address;
            item.req_time_ps   = $time;
            cnt_inval++;

            `uvm_info("OPC_L15_MON",
                $sformatf("[t=%0t] INVAL: addr=0x%010h (total=%0d)",
                    $time, item.inval_address, cnt_inval),
                UVM_MEDIUM)

            inval_ap.write(item);
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("OPC_L15_MON",
            $sformatf("L1.5 TRI: LOAD=%0d STORE=%0d IFILL=%0d AMO=%0d FLUSH=%0d INVAL=%0d",
                cnt_load, cnt_store, cnt_ifill, cnt_amo, cnt_flush, cnt_inval),
            UVM_LOW)
        if (pending_q.size() > 0)
            `uvm_warning("OPC_L15_MON",
                $sformatf("%0d requisicao(oes) sem resposta ao fim da simulacao",
                    pending_q.size()))
    endfunction

endclass : uvmt_opc_l15_tri_mon_c

`endif // __UVMT_OPC_L15_TRI_MON_SV__
