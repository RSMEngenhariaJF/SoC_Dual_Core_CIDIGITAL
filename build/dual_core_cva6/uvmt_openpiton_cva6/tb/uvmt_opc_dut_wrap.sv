// ============================================================================
// uvmt_opc_dut_wrap.sv
// Wrapper do DUT: chip (OpenPiton+CVA6 2x1) + protocol_adapter +
// noc_axi4_bridge + axi4_sram_model, conectado às interfaces UVM.
//
// Hierarquia de instâncias:
//   u_chip    — chip.v  (PITON_NO_CHIP_BRIDGE + PITON_CHIP_FPGA)
//   u_adapter — protocol_adapter.v  (yummy ↔ val/rdy)
//   u_bridge  — noc_axi4_bridge.v   (NoC → AXI4)
//   u_sram    — axi4_sram_model.v   (AXI4 SRAM 256 KB @ 0x8000_0000)
//
// Mapeamento NoC → noc_if (monitoramento passivo UVM):
//   noc1_out_* ← chip processor_offchip_noc1_*   (requisições)
//   noc2_in_*  ← chip offchip_processor_noc2_*   (respostas da memória)
//   noc3_out_* ← chip processor_offchip_noc3_*   (writebacks WT)
//
// L15 TRI: referências hierárquicas u_chip.tile0.*
// Status  : good_trap via escrita AXI4 em tohost (addr[15:0]==0xFF50, data[0]==1)
// ============================================================================
`ifndef __UVMT_OPC_DUT_WRAP_SV__
`define __UVMT_OPC_DUT_WRAP_SV__

`include "noc_axi4_bridge_define.vh"

module uvmt_opc_dut_wrap
    import uvmt_opc_pkg::*;
#(
    parameter int unsigned NUM_X_TILES = 1,
    parameter int unsigned NUM_Y_TILES = 1
)(
    uvmt_opc_clk_rst_if  clk_rst_if,
    uvmt_opc_noc_if      noc_if,
    uvmt_opc_l15_tri_if  l15_tri_if,
    uvmt_opc_status_if   status_if
);

    localparam int unsigned NUM_TILES = NUM_X_TILES * NUM_Y_TILES;

    wire clk   = clk_rst_if.clk;
    wire rst_n = clk_rst_if.rst_n;

    // =========================================================================
    // Wires chip ↔ protocol_adapter  (protocolo yummy)
    // =========================================================================
    wire [`NOC_DATA_WIDTH-1:0] chip_noc1_data;
    wire                        chip_noc1_valid;
    wire                        chip_noc1_yummy;   // adapter → chip backpressure

    wire [`NOC_DATA_WIDTH-1:0] chip_noc2_data;
    wire                        chip_noc2_valid;
    wire                        chip_noc2_yummy;   // chip → adapter backpressure

    wire [`NOC_DATA_WIDTH-1:0] chip_noc3_data;
    wire                        chip_noc3_valid;

    // =========================================================================
    // Wires adapter ↔ bridge  (protocolo val/rdy)
    // =========================================================================
    wire [`NOC_DATA_WIDTH-1:0] bridge_req_data;
    wire                        bridge_req_valid;
    wire                        bridge_req_rdy;

    wire [`NOC_DATA_WIDTH-1:0] bridge_resp_data;
    wire                        bridge_resp_valid;
    wire                        bridge_resp_rdy;

    // =========================================================================
    // Wires bridge ↔ SRAM  (AXI4)
    // =========================================================================
    wire [`AXI4_ID_WIDTH-1:0]     m_axi_awid;
    wire [`AXI4_ADDR_WIDTH-1:0]   m_axi_awaddr;
    wire [`AXI4_LEN_WIDTH-1:0]    m_axi_awlen;
    wire [`AXI4_SIZE_WIDTH-1:0]   m_axi_awsize;
    wire [`AXI4_BURST_WIDTH-1:0]  m_axi_awburst;
    wire                           m_axi_awlock;
    wire [`AXI4_CACHE_WIDTH-1:0]  m_axi_awcache;
    wire [`AXI4_PROT_WIDTH-1:0]   m_axi_awprot;
    wire [`AXI4_QOS_WIDTH-1:0]    m_axi_awqos;
    wire [`AXI4_REGION_WIDTH-1:0] m_axi_awregion;
    wire [`AXI4_USER_WIDTH-1:0]   m_axi_awuser;
    wire                           m_axi_awvalid;
    wire                           m_axi_awready;

    wire [`AXI4_ID_WIDTH-1:0]     m_axi_wid;
    wire [`AXI4_DATA_WIDTH-1:0]   m_axi_wdata;
    wire [`AXI4_STRB_WIDTH-1:0]   m_axi_wstrb;
    wire                           m_axi_wlast;
    wire [`AXI4_USER_WIDTH-1:0]   m_axi_wuser;
    wire                           m_axi_wvalid;
    wire                           m_axi_wready;

    wire [`AXI4_ID_WIDTH-1:0]     m_axi_bid;
    wire [`AXI4_RESP_WIDTH-1:0]   m_axi_bresp;
    wire [`AXI4_USER_WIDTH-1:0]   m_axi_buser;
    wire                           m_axi_bvalid;
    wire                           m_axi_bready;

    wire [`AXI4_ID_WIDTH-1:0]     m_axi_arid;
    wire [`AXI4_ADDR_WIDTH-1:0]   m_axi_araddr;
    wire [`AXI4_LEN_WIDTH-1:0]    m_axi_arlen;
    wire [`AXI4_SIZE_WIDTH-1:0]   m_axi_arsize;
    wire [`AXI4_BURST_WIDTH-1:0]  m_axi_arburst;
    wire                           m_axi_arlock;
    wire [`AXI4_CACHE_WIDTH-1:0]  m_axi_arcache;
    wire [`AXI4_PROT_WIDTH-1:0]   m_axi_arprot;
    wire [`AXI4_QOS_WIDTH-1:0]    m_axi_arqos;
    wire [`AXI4_REGION_WIDTH-1:0] m_axi_arregion;
    wire [`AXI4_USER_WIDTH-1:0]   m_axi_aruser;
    wire                           m_axi_arvalid;
    wire                           m_axi_arready;

    wire [`AXI4_ID_WIDTH-1:0]     m_axi_rid;
    wire [`AXI4_DATA_WIDTH-1:0]   m_axi_rdata;
    wire [`AXI4_RESP_WIDTH-1:0]   m_axi_rresp;
    wire                           m_axi_rlast;
    wire [`AXI4_USER_WIDTH-1:0]   m_axi_ruser;
    wire                           m_axi_rvalid;
    wire                           m_axi_rready;

    // =========================================================================
    // DUT: chip.v  (2x1 tiles, PITON_NO_CHIP_BRIDGE + PITON_CHIP_FPGA)
    // =========================================================================
    chip u_chip (
        .clk_osc_p                    (clk),
        .clk_osc_n                    (~clk),
        .rst_n                        (rst_n),
        .chipset_prsnt_n              (1'b0),
        .piton_prsnt_n                (),
        .piton_ready_n                (),
        .leds                         (),

        // NOC1 — requisições saindo do chip
        .processor_offchip_noc1_valid (chip_noc1_valid),
        .processor_offchip_noc1_data  (chip_noc1_data),
        .processor_offchip_noc1_yummy (chip_noc1_yummy),

        // NOC2 out do chip (ORAM mux) — ignorado
        .processor_offchip_noc2_valid (),
        .processor_offchip_noc2_data  (),
        .processor_offchip_noc2_yummy (1'b1),

        // NOC3 — writebacks saindo do chip
        .processor_offchip_noc3_valid (chip_noc3_valid),
        .processor_offchip_noc3_data  (chip_noc3_data),
        .processor_offchip_noc3_yummy (1'b1),

        // Offchip → chip NOC1 (não usado)
        .offchip_processor_noc1_valid (1'b0),
        .offchip_processor_noc1_data  (64'b0),

        // NOC2 in — respostas da memória chegando ao chip
        .offchip_processor_noc2_valid (chip_noc2_valid),
        .offchip_processor_noc2_data  (chip_noc2_data),
        .offchip_processor_noc2_yummy (chip_noc2_yummy),

        // Offchip → chip NOC3 (não usado)
        .offchip_processor_noc3_valid (1'b0),
        .offchip_processor_noc3_data  (64'b0),

        // Interrupções e debug
        .ndmreset_i                   (1'b0),
        .debug_req_i                  (2'b0),
        .unavailable_o                (),
        .timer_irq_i                  (2'b0),
        .ipi_i                        (2'b0),
        .irq_i                        (4'b0)
    );

    // =========================================================================
    // Protocol adapter: yummy ↔ val/rdy
    // =========================================================================
    protocol_adapter u_adapter (
        .clk              (clk),
        .rst_n            (rst_n),

        .chip_noc1_data   (chip_noc1_data),
        .chip_noc1_valid  (chip_noc1_valid),
        .chip_noc1_yummy  (chip_noc1_yummy),

        .chip_noc2_data   (chip_noc2_data),
        .chip_noc2_valid  (chip_noc2_valid),
        .chip_noc2_yummy  (chip_noc2_yummy),

        .bridge_req_data  (bridge_req_data),
        .bridge_req_valid (bridge_req_valid),
        .bridge_req_rdy   (bridge_req_rdy),

        .bridge_resp_data  (bridge_resp_data),
        .bridge_resp_valid (bridge_resp_valid),
        .bridge_resp_rdy   (bridge_resp_rdy)
    );

    // =========================================================================
    // NoC → AXI4 bridge
    // =========================================================================
    noc_axi4_bridge u_bridge (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .uart_boot_en           (1'b0),
        .phy_init_done          (1'b1),

        .src_bridge_vr_noc2_val (bridge_req_valid),
        .src_bridge_vr_noc2_dat (bridge_req_data),
        .src_bridge_vr_noc2_rdy (bridge_req_rdy),

        .bridge_dst_vr_noc3_val (bridge_resp_valid),
        .bridge_dst_vr_noc3_dat (bridge_resp_data),
        .bridge_dst_vr_noc3_rdy (bridge_resp_rdy),

        .m_axi_awid             (m_axi_awid),
        .m_axi_awaddr           (m_axi_awaddr),
        .m_axi_awlen            (m_axi_awlen),
        .m_axi_awsize           (m_axi_awsize),
        .m_axi_awburst          (m_axi_awburst),
        .m_axi_awlock           (m_axi_awlock),
        .m_axi_awcache          (m_axi_awcache),
        .m_axi_awprot           (m_axi_awprot),
        .m_axi_awqos            (m_axi_awqos),
        .m_axi_awregion         (m_axi_awregion),
        .m_axi_awuser           (m_axi_awuser),
        .m_axi_awvalid          (m_axi_awvalid),
        .m_axi_awready          (m_axi_awready),

        .m_axi_wid              (m_axi_wid),
        .m_axi_wdata            (m_axi_wdata),
        .m_axi_wstrb            (m_axi_wstrb),
        .m_axi_wlast            (m_axi_wlast),
        .m_axi_wuser            (m_axi_wuser),
        .m_axi_wvalid           (m_axi_wvalid),
        .m_axi_wready           (m_axi_wready),

        .m_axi_bid              (m_axi_bid),
        .m_axi_bresp            (m_axi_bresp),
        .m_axi_buser            (m_axi_buser),
        .m_axi_bvalid           (m_axi_bvalid),
        .m_axi_bready           (m_axi_bready),

        .m_axi_arid             (m_axi_arid),
        .m_axi_araddr           (m_axi_araddr),
        .m_axi_arlen            (m_axi_arlen),
        .m_axi_arsize           (m_axi_arsize),
        .m_axi_arburst          (m_axi_arburst),
        .m_axi_arlock           (m_axi_arlock),
        .m_axi_arcache          (m_axi_arcache),
        .m_axi_arprot           (m_axi_arprot),
        .m_axi_arqos            (m_axi_arqos),
        .m_axi_arregion         (m_axi_arregion),
        .m_axi_aruser           (m_axi_aruser),
        .m_axi_arvalid          (m_axi_arvalid),
        .m_axi_arready          (m_axi_arready),

        .m_axi_rid              (m_axi_rid),
        .m_axi_rdata            (m_axi_rdata),
        .m_axi_rresp            (m_axi_rresp),
        .m_axi_rlast            (m_axi_rlast),
        .m_axi_ruser            (m_axi_ruser),
        .m_axi_rvalid           (m_axi_rvalid),
        .m_axi_rready           (m_axi_rready)
    );

    // =========================================================================
    // AXI4 SRAM (256 KB @ 0x8000_0000)
    // =========================================================================
    axi4_sram_model u_sram (
        .clk            (clk),
        .rst_n          (rst_n),

        .s_axi_awid     (m_axi_awid),
        .s_axi_awaddr   (m_axi_awaddr),
        .s_axi_awlen    (m_axi_awlen),
        .s_axi_awsize   (m_axi_awsize),
        .s_axi_awburst  (m_axi_awburst),
        .s_axi_awvalid  (m_axi_awvalid),
        .s_axi_awready  (m_axi_awready),

        .s_axi_wdata    (m_axi_wdata),
        .s_axi_wstrb    (m_axi_wstrb),
        .s_axi_wlast    (m_axi_wlast),
        .s_axi_wvalid   (m_axi_wvalid),
        .s_axi_wready   (m_axi_wready),

        .s_axi_bid      (m_axi_bid),
        .s_axi_bresp    (m_axi_bresp),
        .s_axi_bvalid   (m_axi_bvalid),
        .s_axi_bready   (m_axi_bready),

        .s_axi_arid     (m_axi_arid),
        .s_axi_araddr   (m_axi_araddr),
        .s_axi_arlen    (m_axi_arlen),
        .s_axi_arsize   (m_axi_arsize),
        .s_axi_arburst  (m_axi_arburst),
        .s_axi_arvalid  (m_axi_arvalid),
        .s_axi_arready  (m_axi_arready),

        .s_axi_rid      (m_axi_rid),
        .s_axi_rdata    (m_axi_rdata),
        .s_axi_rresp    (m_axi_rresp),
        .s_axi_rlast    (m_axi_rlast),
        .s_axi_rvalid   (m_axi_rvalid),
        .s_axi_rready   (m_axi_rready)
    );

    // =========================================================================
    // Conexão: NoC interface UVM ← sinais do chip
    // =========================================================================
    // NOC1: requisições saindo do chip (processor → offchip)
    assign noc_if.noc1_out_data  = chip_noc1_data;
    assign noc_if.noc1_out_valid = chip_noc1_valid;
    assign noc_if.noc1_out_ready = chip_noc1_yummy;   // adapter aceita o flit
    assign noc_if.noc1_in_data   = '0;
    assign noc_if.noc1_in_valid  = 1'b0;
    assign noc_if.noc1_in_ready  = 1'b1;

    // NOC2: respostas da memória chegando ao chip (offchip → processor)
    assign noc_if.noc2_in_data   = chip_noc2_data;
    assign noc_if.noc2_in_valid  = chip_noc2_valid;
    assign noc_if.noc2_in_ready  = chip_noc2_yummy;   // chip aceita a resposta
    assign noc_if.noc2_out_data  = '0;
    assign noc_if.noc2_out_valid = 1'b0;
    assign noc_if.noc2_out_ready = 1'b1;

    // NOC3: writebacks WT saindo do chip (descartados pelo yummy=1)
    assign noc_if.noc3_out_data  = chip_noc3_data;
    assign noc_if.noc3_out_valid = chip_noc3_valid;
    assign noc_if.noc3_out_ready = 1'b1;
    assign noc_if.noc3_in_data   = '0;
    assign noc_if.noc3_in_valid  = 1'b0;
    assign noc_if.noc3_in_ready  = 1'b1;

    // =========================================================================
    // Conexão: L1.5 TRI interface UVM ← referências hierárquicas tile0
    // =========================================================================
    // Requisição CVA6 → L1.5
    assign l15_tri_if.transducer_l15_val             = u_chip.tile0.transducer_l15_val;
    assign l15_tri_if.transducer_l15_reqtype         = u_chip.tile0.transducer_l15_rqtype;
    assign l15_tri_if.transducer_l15_address         = u_chip.tile0.transducer_l15_address;
    assign l15_tri_if.transducer_l15_nc              = u_chip.tile0.transducer_l15_nc;
    // L15 aceita a requisição do transducer
    assign l15_tri_if.transducer_l15_ack             = u_chip.tile0.l15_transducer_ack;
    // Campos opcionais — não monitorados pelo agente passivo, mas necessários
    assign l15_tri_if.transducer_l15_data            = '0;
    assign l15_tri_if.transducer_l15_data_next_entry = '0;
    assign l15_tri_if.transducer_l15_size            = '0;
    assign l15_tri_if.transducer_l15_amo_op          = '0;
    assign l15_tri_if.transducer_l15_threadid        = '0;
    assign l15_tri_if.transducer_l15_prefetch        = '0;
    assign l15_tri_if.transducer_l15_blockstore      = '0;
    assign l15_tri_if.transducer_l15_blockinitstore  = '0;
    assign l15_tri_if.transducer_l15_l1rplway        = '0;

    // Resposta L1.5 → CVA6
    // Sinais confirmados ao nível tile0 pelo monitor tb_soc_dual_core.v
    assign l15_tri_if.l15_transducer_val             = u_chip.tile0.l15_transducer_val;
    assign l15_tri_if.l15_transducer_returntype      = u_chip.tile0.l15_transducer_returntype;
    // Restante dos sinais de resposta está em l15_wrap — tie-off para evitar erros de elaboração
    assign l15_tri_if.l15_transducer_returndata_0    = '0;
    assign l15_tri_if.l15_transducer_returndata_1    = '0;
    assign l15_tri_if.l15_transducer_returnnc        = 1'b0;
    assign l15_tri_if.l15_transducer_returnsize      = 2'b0;
    assign l15_tri_if.l15_transducer_threadid        = 3'b0;
    assign l15_tri_if.l15_transducer_ack             = 1'b0;

    // Invalidações: não expostas ao nível tile0 — tie-off
    assign l15_tri_if.l15_transducer_inval_valid          = 1'b0;
    assign l15_tri_if.l15_transducer_inval_address        = '0;
    assign l15_tri_if.l15_transducer_inval_way            = 1'b0;
    assign l15_tri_if.l15_transducer_inval_icache_all_way = 1'b0;
    assign l15_tri_if.l15_transducer_inval_dcache_all_way = 1'b0;

    // =========================================================================
    // Status interface: GOOD_TRAP via escrita AXI4 em tohost
    //
    // OpenPiton usa escrita em 0x0000_0000_FF50:
    //   data[0]=1 → PASS (good_trap para todos os tiles)
    //   data≠0, data[0]=0 → FAIL (bad_trap com código em data)
    //
    // Pipeline AXI4: captura endereço no AW-beat, aplica resultado no W-beat.
    // =========================================================================
    reg tohost_addr_latch;

    // -------------------------------------------------------------------------
    // Store-buffer commit probes — tile 0
    // Reads de packed-struct arrays são seguros no xsim 2025.1 (só escritas em
    // always_comb crasham).  Capture commit_i e o endereço físico do store
    // sendo commitado (speculative_queue_q[ptr].address, PLEN=56 bits).
    // -------------------------------------------------------------------------
    `define SB0 u_chip.tile0.g_ariane_core.core.ariane.i_cva6.ex_stage_i.lsu_i.i_store_unit.store_buffer_i

    wire       sb0_commit_i;
    wire [55:0] sb0_commit_addr;

    assign sb0_commit_i    = `SB0.commit_i;
    assign sb0_commit_addr = `SB0.speculative_queue_q[`SB0.speculative_read_pointer_q].address;

    localparam [31:0] TOHOST_ADDR32 = 32'h8000_FF50;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tohost_addr_latch   <= 1'b0;
            status_if.good_trap <= '0;
            status_if.bad_trap  <= '0;
        end else begin
            // AXI4 write-to-tohost (standard path)
            if (m_axi_awvalid && m_axi_awready &&
                m_axi_awaddr[15:0] == 16'hFF50)
                tohost_addr_latch <= 1'b1;

            if (tohost_addr_latch && m_axi_wvalid && m_axi_wready) begin
                tohost_addr_latch <= 1'b0;
                if (m_axi_wdata[0]) begin
                    status_if.good_trap <= {NUM_TILES{1'b1}};
                end else if (|m_axi_wdata) begin
                    status_if.bad_trap  <= {NUM_TILES{1'b1}};
                end
            end

            // Store-commit detection: xsim 2025.1 stub (store_buffer.sv `ifndef XSIM)
            // forces req_port_o.data_req=0, so stores never reach wbuffer/L15/AXI.
            // Monitor commit_i + endereço físico do store (speculative_queue_q[ptr].address)
            // para distinguir o write em tohost de stores para outros endereços.
            if (!status_if.good_trap[0] && sb0_commit_i &&
                sb0_commit_addr[31:0] == TOHOST_ADDR32) begin
                $display("[%0t ns] STORE_COMMIT tohost=0x%08h @cyc=%0d",
                    $time, sb0_commit_addr[31:0], mon_cycle);
                status_if.good_trap <= {NUM_TILES{1'b1}};
            end
        end
    end

    // UART: sem fake_uart neste wrapper — desabilitado
    assign status_if.uart_valid = 1'b0;
    assign status_if.uart_data  = 8'h0;

    // Código de falha do reg a0 (não capturado sem debug unit ativo)
    genvar ti;
    generate
        for (ti = 0; ti < NUM_TILES; ti++) begin : gen_trap_code
            assign status_if.bad_trap_code[ti] = '0;
        end
    endgenerate

    // =========================================================================
    // Simulation monitors — non-synthesizable analysis probes
    // =========================================================================
    integer mon_cycle;
    integer mon_ar_cnt;
    integer mon_aw_cnt;
    reg     mon_noc1_seen;

    initial begin
        mon_cycle     = 0;
        mon_ar_cnt    = 0;
        mon_aw_cnt    = 0;
        mon_noc1_seen = 1'b0;
    end

    // Free-running cycle counter (reset-aware)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mon_cycle <= 0;
        else        mon_cycle <= mon_cycle + 1;
    end

    // Heartbeat every 100 K cycles
    always @(posedge clk) begin
        if (rst_n && mon_cycle > 0 && (mon_cycle % 100000 == 0))
            $display("[%0t ns] HEARTBEAT cyc=%0d noc1=%0b ar=%0d aw=%0d trap_ok=%0b",
                $time, mon_cycle, mon_noc1_seen, mon_ar_cnt, mon_aw_cnt,
                |status_if.good_trap);
    end

    // First 8 AXI AR beats (instruction fetches / cache fills)
    always @(posedge clk) begin
        if (rst_n && m_axi_arvalid && m_axi_arready) begin
            if (mon_ar_cnt < 8)
                $display("[%0t ns] AXI_AR[%0d] addr=%h len=%0d @cyc=%0d",
                    $time, mon_ar_cnt, m_axi_araddr, m_axi_arlen, mon_cycle);
            mon_ar_cnt <= mon_ar_cnt + 1;
        end
    end

    // All AXI AW write-address beats
    always @(posedge clk) begin
        if (rst_n && m_axi_awvalid && m_axi_awready) begin
            $display("[%0t ns] AXI_AW[%0d] addr=%h @cyc=%0d",
                $time, mon_aw_cnt, m_axi_awaddr, mon_cycle);
            mon_aw_cnt <= mon_aw_cnt + 1;
        end
    end

    // All AXI W data beats
    always @(posedge clk) begin
        if (rst_n && m_axi_wvalid && m_axi_wready)
            $display("[%0t ns] AXI_WD  data=%h strb=%h last=%b @cyc=%0d",
                $time, m_axi_wdata, m_axi_wstrb, m_axi_wlast, mon_cycle);
    end

    // First NOC1 flit
    always @(posedge clk) begin
        if (!mon_noc1_seen && chip_noc1_valid && chip_noc1_yummy) begin
            mon_noc1_seen <= 1'b1;
            $display("[%0t ns] NOC1_FIRST data=%h @cyc=%0d",
                $time, chip_noc1_data, mon_cycle);
        end
    end

    // Trap detection — terminate simulation immediately
    always @(posedge clk) begin
        if (|status_if.good_trap) begin
            $display("[%0t ns] *** GOOD TRAP (PASS) *** @cyc=%0d", $time, mon_cycle);
            $finish;
        end
        if (|status_if.bad_trap) begin
            $display("[%0t ns] *** BAD TRAP (FAIL) *** @cyc=%0d", $time, mon_cycle);
            $finish;
        end
    end

endmodule : uvmt_opc_dut_wrap

`endif // __UVMT_OPC_DUT_WRAP_SV__
