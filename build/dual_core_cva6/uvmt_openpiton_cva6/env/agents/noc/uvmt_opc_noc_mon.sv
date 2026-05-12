// ============================================================================
// uvmt_opc_noc_mon.sv
// Monitor passivo das tres redes NoC do P-Mesh.
// Captura pacotes completos (header + payload flits) via handshake valid/ready.
// Porta o comportamento dos monitors Verilog do piton/verif/env/manycore/.
// ============================================================================
`ifndef __UVMT_OPC_NOC_MON_SV__
`define __UVMT_OPC_NOC_MON_SV__

class uvmt_opc_noc_mon_c extends uvm_monitor;

    `uvm_component_utils(uvmt_opc_noc_mon_c)

    virtual uvmt_opc_noc_if vif;
    uvmt_opc_cfg_c cfg;

    // Analysis ports - separados por rede e por funcao
    uvm_analysis_port #(uvmt_opc_noc_seq_item_c) noc1_ap;
    uvm_analysis_port #(uvmt_opc_noc_seq_item_c) noc2_ap;
    uvm_analysis_port #(uvmt_opc_noc_seq_item_c) noc3_ap;
    uvm_analysis_port #(uvmt_opc_noc_seq_item_c) coherence_ap; // so invalidacoes

    // Contadores (equivalente ao output do monitor Verilog do OpenPiton)
    protected longint unsigned cnt[3];  // cnt[0]=NoC1, [1]=NoC2, [2]=NoC3
    protected longint unsigned inval_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        foreach (cnt[i]) cnt[i] = 0;
        inval_cnt = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        noc1_ap      = new("noc1_ap",      this);
        noc2_ap      = new("noc2_ap",      this);
        noc3_ap      = new("noc3_ap",      this);
        coherence_ap = new("coherence_ap", this);

        if (!uvm_config_db #(virtual uvmt_opc_noc_if)::get(
                this, "", "noc_vif", vif))
            `uvm_fatal("OPC_NOC_MON", "noc_vif nao encontrado no config_db")
        if (!uvm_config_db #(uvmt_opc_cfg_c)::get(
                this, "", "cfg", cfg))
            `uvm_fatal("OPC_NOC_MON", "cfg nao encontrado no config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // Aguarda reset
        @(posedge vif.clk iff vif.rst_n === 1'b1);
        @(posedge vif.clk);
        `uvm_info("OPC_NOC_MON", "Monitor NoC iniciado", UVM_LOW)
        fork
            capture_noc1();
            capture_noc2();
            capture_noc3();
        join
    endtask

    // -------------------------------------------------------------------------
    // Tarefa generica: captura um pacote completo de uma rede NoC.
    // valid & ready no mesmo ciclo = flit aceito.
    // -------------------------------------------------------------------------
    task automatic capture_packet(
        input  opc_noc_network_e              net,
        input  uvm_analysis_port #(uvmt_opc_noc_seq_item_c) ap
    );
        uvmt_opc_noc_seq_item_c item;
        logic [63:0] hdr_flit;
        logic [63:0] payload_flit;
        int unsigned remaining;

        item = uvmt_opc_noc_seq_item_c::type_id::create("noc_item");
        item.network      = net;
        item.timestamp_ps = $time;

        // Decodifica header ja capturado pelo chamador
        item.decode_header_flit(hdr_flit);

        // Captura flits de payload (pkt_len - 1 flits restantes)
        remaining = (item.pkt_len > 0) ? item.pkt_len - 1 : 0;

        for (int i = 0; i < remaining; i++) begin
            case (net)
                NOC_NETWORK_1: begin
                    @(vif.mon_cb iff (vif.mon_cb.noc1_out_valid &&
                                      vif.mon_cb.noc1_out_ready));
                    payload_flit = vif.mon_cb.noc1_out_data;
                end
                NOC_NETWORK_2: begin
                    @(vif.mon_cb iff (vif.mon_cb.noc2_out_valid &&
                                      vif.mon_cb.noc2_out_ready));
                    payload_flit = vif.mon_cb.noc2_out_data;
                end
                default: begin  // NOC_NETWORK_3
                    @(vif.mon_cb iff (vif.mon_cb.noc3_out_valid &&
                                      vif.mon_cb.noc3_out_ready));
                    payload_flit = vif.mon_cb.noc3_out_data;
                end
            endcase
            // Primeiro flit de payload contem o endereco
            if (i == 0) item.decode_addr_flit(payload_flit);
            // Segundo contem o dado (para STORE/AMO)
            if (i == 1) item.data = payload_flit;
        end

        // Publicar no port da rede
        ap.write(item);
        cnt[int'(net)]++;

        // Mensagens de coerencia tem port dedicado
        if (item.is_coherence_msg) begin
            coherence_ap.write(item);
            inval_cnt++;
            `uvm_info("OPC_NOC_MON",
                $sformatf("[t=%0t] COERENCIA: %s addr=0x%010h",
                    $time, item.msg_type.name(), item.address),
                UVM_MEDIUM)
        end else begin
            `uvm_info("OPC_NOC_MON",
                $sformatf("[NoC%0d t=%0t] %s addr=0x%010h",
                    int'(net)+1, $time, item.msg_type.name(), item.address),
                UVM_HIGH)
        end
    endtask

    // ---- Loops de captura por rede -----------------------------------------

    task automatic capture_noc1();
        logic [63:0] hdr;
        forever begin
            @(vif.mon_cb iff (vif.mon_cb.noc1_out_valid &&
                              vif.mon_cb.noc1_out_ready));
            hdr = vif.mon_cb.noc1_out_data;
            capture_packet(NOC_NETWORK_1, noc1_ap);
        end
    endtask

    task automatic capture_noc2();
        logic [63:0] hdr;
        forever begin
            @(vif.mon_cb iff (vif.mon_cb.noc2_out_valid &&
                              vif.mon_cb.noc2_out_ready));
            hdr = vif.mon_cb.noc2_out_data;
            capture_packet(NOC_NETWORK_2, noc2_ap);
        end
    endtask

    task automatic capture_noc3();
        logic [63:0] hdr;
        forever begin
            @(vif.mon_cb iff (vif.mon_cb.noc3_out_valid &&
                              vif.mon_cb.noc3_out_ready));
            hdr = vif.mon_cb.noc3_out_data;
            capture_packet(NOC_NETWORK_3, noc3_ap);
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("OPC_NOC_MON",
            $sformatf("Resumo NoC: NoC1=%0d | NoC2=%0d | NoC3=%0d | Invalidacoes=%0d",
                cnt[0], cnt[1], cnt[2], inval_cnt),
            UVM_LOW)
    endfunction

endclass : uvmt_opc_noc_mon_c

`endif // __UVMT_OPC_NOC_MON_SV__
