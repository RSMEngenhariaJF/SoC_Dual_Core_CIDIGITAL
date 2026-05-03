// Testbench: Dual-Core CVA6 SoC — chip.v como DUT + noc_axi4_bridge + AXI4 SRAM
// Arquitetura UVM-ready: fronteira DUT em chip.v, memória exposta via AXI4.
//
// Hierarquia:
//   tb_soc_dual_core
//   ├── u_chip          (chip.v — PITON_NO_CHIP_BRIDGE + PITON_CHIP_FPGA)
//   ├── u_adapter       (protocol_adapter.v — yummy ↔ val/rdy)
//   ├── u_bridge        (noc_axi4_bridge.v — NoC → AXI4)
//   └── u_sram          (axi4_sram_model.v — AXI4 slave SRAM)
//
// Fluxo de memória:
//   core → L1.5 → L2 → NoC1(chip.W) → adapter → bridge → AXI4 → SRAM → AXI4 → bridge → adapter → NoC2(chip.W) → L2

`timescale 1ns/1ps

`include "define.tmp.h"
`include "noc_axi4_bridge_define.vh"

module tb_soc_dual_core;

// ------------------------------------------------------------
// Parâmetros
// ------------------------------------------------------------
parameter CLK_PERIOD   = 10;   // 100 MHz
parameter RESET_CYCLES = 200;
parameter SIM_CYCLES   = 10000;

// ------------------------------------------------------------
// Clock e reset
// ------------------------------------------------------------
reg clk;
reg rst_n;

initial clk = 1'b0;
always #(CLK_PERIOD/2) clk = ~clk;

initial begin
    rst_n = 1'b0;
    repeat (RESET_CYCLES) @(posedge clk);
    rst_n = 1'b1;
    $display("[%0t] Reset deasserted.", $time);
end

// ------------------------------------------------------------
// Watchdog
// ------------------------------------------------------------
initial begin
    #(CLK_PERIOD * (RESET_CYCLES + SIM_CYCLES + 100));
    $display("[%0t] TIMEOUT após %0d ciclos.", $time, RESET_CYCLES + SIM_CYCLES);
    $finish;
end

// ------------------------------------------------------------
// Wires chip ↔ protocol_adapter
// ------------------------------------------------------------
// NOC1: chip → memória (requisições)
wire [`NOC_DATA_WIDTH-1:0] chip_noc1_data;
wire                        chip_noc1_valid;
wire                        chip_noc1_yummy; // feedback para o chip

// NOC2: memória → chip (respostas)
wire [`NOC_DATA_WIDTH-1:0] chip_noc2_data;
wire                        chip_noc2_valid;
wire                        chip_noc2_yummy; // feedback do chip

// NOC3: chip → memória (writebacks WT_DCACHE — descartados)
wire [`NOC_DATA_WIDTH-1:0] chip_noc3_data;
wire                        chip_noc3_valid;

// ------------------------------------------------------------
// Wires adapter ↔ bridge (val/rdy)
// ------------------------------------------------------------
wire [`NOC_DATA_WIDTH-1:0] bridge_req_data;
wire                        bridge_req_valid;
wire                        bridge_req_rdy;

wire [`NOC_DATA_WIDTH-1:0] bridge_resp_data;
wire                        bridge_resp_valid;
wire                        bridge_resp_rdy;

// ------------------------------------------------------------
// Wires bridge ↔ SRAM (AXI4)
// ------------------------------------------------------------
wire [`AXI4_ID_WIDTH-1:0]    m_axi_awid;
wire [`AXI4_ADDR_WIDTH-1:0]  m_axi_awaddr;
wire [`AXI4_LEN_WIDTH-1:0]   m_axi_awlen;
wire [`AXI4_SIZE_WIDTH-1:0]  m_axi_awsize;
wire [`AXI4_BURST_WIDTH-1:0] m_axi_awburst;
wire                          m_axi_awlock;
wire [`AXI4_CACHE_WIDTH-1:0] m_axi_awcache;
wire [`AXI4_PROT_WIDTH-1:0]  m_axi_awprot;
wire [`AXI4_QOS_WIDTH-1:0]   m_axi_awqos;
wire [`AXI4_REGION_WIDTH-1:0]m_axi_awregion;
wire [`AXI4_USER_WIDTH-1:0]  m_axi_awuser;
wire                          m_axi_awvalid;
wire                          m_axi_awready;

wire [`AXI4_ID_WIDTH-1:0]    m_axi_wid;
wire [`AXI4_DATA_WIDTH-1:0]  m_axi_wdata;
wire [`AXI4_STRB_WIDTH-1:0]  m_axi_wstrb;
wire                          m_axi_wlast;
wire [`AXI4_USER_WIDTH-1:0]  m_axi_wuser;
wire                          m_axi_wvalid;
wire                          m_axi_wready;

wire [`AXI4_ID_WIDTH-1:0]    m_axi_bid;
wire [`AXI4_RESP_WIDTH-1:0]  m_axi_bresp;
wire [`AXI4_USER_WIDTH-1:0]  m_axi_buser;
wire                          m_axi_bvalid;
wire                          m_axi_bready;

wire [`AXI4_ID_WIDTH-1:0]    m_axi_arid;
wire [`AXI4_ADDR_WIDTH-1:0]  m_axi_araddr;
wire [`AXI4_LEN_WIDTH-1:0]   m_axi_arlen;
wire [`AXI4_SIZE_WIDTH-1:0]  m_axi_arsize;
wire [`AXI4_BURST_WIDTH-1:0] m_axi_arburst;
wire                          m_axi_arlock;
wire [`AXI4_CACHE_WIDTH-1:0] m_axi_arcache;
wire [`AXI4_PROT_WIDTH-1:0]  m_axi_arprot;
wire [`AXI4_QOS_WIDTH-1:0]   m_axi_arqos;
wire [`AXI4_REGION_WIDTH-1:0]m_axi_arregion;
wire [`AXI4_USER_WIDTH-1:0]  m_axi_aruser;
wire                          m_axi_arvalid;
wire                          m_axi_arready;

wire [`AXI4_ID_WIDTH-1:0]    m_axi_rid;
wire [`AXI4_DATA_WIDTH-1:0]  m_axi_rdata;
wire [`AXI4_RESP_WIDTH-1:0]  m_axi_rresp;
wire                          m_axi_rlast;
wire [`AXI4_USER_WIDTH-1:0]  m_axi_ruser;
wire                          m_axi_rvalid;
wire                          m_axi_rready;

// ------------------------------------------------------------
// DUT: chip.v  (PITON_NO_CHIP_BRIDGE + PITON_CHIP_FPGA)
// ------------------------------------------------------------
// PITON_CHIP_FPGA → piton_system.vh define PITON_FPGA_CLKS_GEN
// → chip porta clk_osc_p/n (MMCM stub passa clk_osc_p para core_ref_clk)
chip u_chip (
    .clk_osc_p                   (clk),        // clock principal → MMCM stub
    .clk_osc_n                   (~clk),       // complemento diferencial
    .rst_n                       (rst_n),
    .chipset_prsnt_n             (1'b0),        // chipset presente (ativo-baixo)
    .piton_prsnt_n               (),           // outputs do chip — não conectados
    .piton_ready_n               (),
    .leds                        (),

    // NOC1 — requisições de memória saindo do chip
    .processor_offchip_noc1_valid(chip_noc1_valid),
    .processor_offchip_noc1_data (chip_noc1_data),
    .processor_offchip_noc1_yummy(chip_noc1_yummy),

    // NOC2 — respostas chegando ao chip (ORAM mux bypass)
    .processor_offchip_noc2_valid(),            // saída do chip (ORAM), ignorada
    .processor_offchip_noc2_data (),
    .processor_offchip_noc2_yummy(1'b1),        // chip aceita noc2 de volta

    // NOC3 — writebacks saindo do chip (WT → descartados)
    .processor_offchip_noc3_valid(chip_noc3_valid),
    .processor_offchip_noc3_data (chip_noc3_data),
    .processor_offchip_noc3_yummy(1'b1),        // sempre aceita (descarta)

    // Offchip → chip NOC1 (não usado)
    .offchip_processor_noc1_valid(1'b0),
    .offchip_processor_noc1_data (64'b0),

    // Offchip → chip NOC2 (respostas da memória)
    .offchip_processor_noc2_valid(chip_noc2_valid),
    .offchip_processor_noc2_data (chip_noc2_data),
    .offchip_processor_noc2_yummy(chip_noc2_yummy),

    // Offchip → chip NOC3 (não usado)
    .offchip_processor_noc3_valid(1'b0),
    .offchip_processor_noc3_data (64'b0),

    // Interrupções e debug (tie-off)
    .ndmreset_i                  (1'b0),
    .debug_req_i                 (2'b0),
    .unavailable_o               (),           // output — não conectado
    .timer_irq_i                 (2'b0),
    .ipi_i                       (2'b0),
    .irq_i                       (4'b0)
);

// ------------------------------------------------------------
// Protocol adapter: yummy ↔ val/rdy
// ------------------------------------------------------------
protocol_adapter u_adapter (
    .clk             (clk),
    .rst_n           (rst_n),

    // Lado chip (yummy)
    .chip_noc1_data  (chip_noc1_data),
    .chip_noc1_valid (chip_noc1_valid),
    .chip_noc1_yummy (chip_noc1_yummy),

    .chip_noc2_data  (chip_noc2_data),
    .chip_noc2_valid (chip_noc2_valid),
    .chip_noc2_yummy (chip_noc2_yummy),

    // Lado bridge (val/rdy)
    .bridge_req_data  (bridge_req_data),
    .bridge_req_valid (bridge_req_valid),
    .bridge_req_rdy   (bridge_req_rdy),

    .bridge_resp_data  (bridge_resp_data),
    .bridge_resp_valid (bridge_resp_valid),
    .bridge_resp_rdy   (bridge_resp_rdy)
);

// ------------------------------------------------------------
// NoC → AXI4 bridge
// ------------------------------------------------------------
noc_axi4_bridge u_bridge (
    .clk              (clk),
    .rst_n            (rst_n),
    .uart_boot_en     (1'b0),
    .phy_init_done    (1'b1),    // memória pronta imediatamente

    // NoC interface (val/rdy)
    .src_bridge_vr_noc2_val (bridge_req_valid),
    .src_bridge_vr_noc2_dat (bridge_req_data),
    .src_bridge_vr_noc2_rdy (bridge_req_rdy),
    .bridge_dst_vr_noc3_val (bridge_resp_valid),
    .bridge_dst_vr_noc3_dat (bridge_resp_data),
    .bridge_dst_vr_noc3_rdy (bridge_resp_rdy),

    // AXI4 master
    .m_axi_awid     (m_axi_awid),
    .m_axi_awaddr   (m_axi_awaddr),
    .m_axi_awlen    (m_axi_awlen),
    .m_axi_awsize   (m_axi_awsize),
    .m_axi_awburst  (m_axi_awburst),
    .m_axi_awlock   (m_axi_awlock),
    .m_axi_awcache  (m_axi_awcache),
    .m_axi_awprot   (m_axi_awprot),
    .m_axi_awqos    (m_axi_awqos),
    .m_axi_awregion (m_axi_awregion),
    .m_axi_awuser   (m_axi_awuser),
    .m_axi_awvalid  (m_axi_awvalid),
    .m_axi_awready  (m_axi_awready),

    .m_axi_wid      (m_axi_wid),
    .m_axi_wdata    (m_axi_wdata),
    .m_axi_wstrb    (m_axi_wstrb),
    .m_axi_wlast    (m_axi_wlast),
    .m_axi_wuser    (m_axi_wuser),
    .m_axi_wvalid   (m_axi_wvalid),
    .m_axi_wready   (m_axi_wready),

    .m_axi_bid      (m_axi_bid),
    .m_axi_bresp    (m_axi_bresp),
    .m_axi_buser    (m_axi_buser),
    .m_axi_bvalid   (m_axi_bvalid),
    .m_axi_bready   (m_axi_bready),

    .m_axi_arid     (m_axi_arid),
    .m_axi_araddr   (m_axi_araddr),
    .m_axi_arlen    (m_axi_arlen),
    .m_axi_arsize   (m_axi_arsize),
    .m_axi_arburst  (m_axi_arburst),
    .m_axi_arlock   (m_axi_arlock),
    .m_axi_arcache  (m_axi_arcache),
    .m_axi_arprot   (m_axi_arprot),
    .m_axi_arqos    (m_axi_arqos),
    .m_axi_arregion (m_axi_arregion),
    .m_axi_aruser   (m_axi_aruser),
    .m_axi_arvalid  (m_axi_arvalid),
    .m_axi_arready  (m_axi_arready),

    .m_axi_rid      (m_axi_rid),
    .m_axi_rdata    (m_axi_rdata),
    .m_axi_rresp    (m_axi_rresp),
    .m_axi_rlast    (m_axi_rlast),
    .m_axi_ruser    (m_axi_ruser),
    .m_axi_rvalid   (m_axi_rvalid),
    .m_axi_rready   (m_axi_rready)
);

// ------------------------------------------------------------
// AXI4 SRAM model  (base: 0x8000_0000, tamanho: 256 KB)
// ------------------------------------------------------------
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

// ------------------------------------------------------------
// Monitor AXI4 — leitura e escrita com conteúdo
// ------------------------------------------------------------
integer axi_rd_count, axi_wr_count;
initial begin
    axi_rd_count = 0;
    axi_wr_count = 0;
end

always @(posedge clk) begin
    // Endereço de leitura aceito
    if (m_axi_arvalid && m_axi_arready) begin
        axi_rd_count <= axi_rd_count + 1;
        $display("[%0t] >>> AXI4 AR  addr=0x%016X id=%0d len=%0d",
                 $time, m_axi_araddr, m_axi_arid, m_axi_arlen);
    end
    // Dado de leitura retornado
    if (m_axi_rvalid && m_axi_rready) begin
        $display("[%0t]     AXI4 R   id=%0d last=%b data[63:0]=0x%016X",
                 $time, m_axi_rid, m_axi_rlast, m_axi_rdata[63:0]);
    end
    // Endereço de escrita aceito
    if (m_axi_awvalid && m_axi_awready) begin
        axi_wr_count <= axi_wr_count + 1;
        $display("[%0t] >>> AXI4 AW  addr=0x%016X id=%0d len=%0d",
                 $time, m_axi_awaddr, m_axi_awid, m_axi_awlen);
    end
    // Dado de escrita enviado
    if (m_axi_wvalid && m_axi_wready) begin
        $display("[%0t]     AXI4 W   last=%b strb=0x%016X data[63:0]=0x%016X",
                 $time, m_axi_wlast, m_axi_wstrb[63:0], m_axi_wdata[63:0]);
    end
    // Resposta de escrita
    if (m_axi_bvalid && m_axi_bready) begin
        $display("[%0t]     AXI4 B   id=%0d resp=%0d",
                 $time, m_axi_bid, m_axi_bresp);
    end
end

// ------------------------------------------------------------
// Monitor NoC1 — primeiro flit que sai do chip
// ------------------------------------------------------------
reg noc1_seen;
initial noc1_seen = 0;
always @(posedge clk) begin
    if (rst_n && chip_noc1_valid && !noc1_seen) begin
        noc1_seen <= 1;
        $display("[%0t] === PRIMEIRO NOC1 FLIT: data=0x%016X", $time, chip_noc1_data);
    end
    if (rst_n && chip_noc1_valid)
        $display("[%0t]     NOC1 flit: 0x%016X yummy=%b", $time, chip_noc1_data, chip_noc1_yummy);
end

// Monitor NoC2 — resposta chegando ao chip
always @(posedge clk) begin
    if (rst_n && chip_noc2_valid)
        $display("[%0t]     NOC2 resp: 0x%016X", $time, chip_noc2_data);
end

// ------------------------------------------------------------
// Monitor bridge — val/rdy interno
// ------------------------------------------------------------
always @(posedge clk) begin
    if (rst_n && bridge_req_valid && bridge_req_rdy)
        $display("[%0t]     BRIDGE REQ: 0x%016X", $time, bridge_req_data);
    if (rst_n && bridge_resp_valid && bridge_resp_rdy)
        $display("[%0t]     BRIDGE RESP: 0x%016X", $time, bridge_resp_data);
end

// ------------------------------------------------------------
// Monitor L15 pipeline profundo
// ------------------------------------------------------------

// spc_grst_l: reset ativo-baixo do L15 gerado pelo CVA6
reg grst_prev;
initial grst_prev = 0;
always @(posedge clk) begin
    if (u_chip.tile0.spc_grst_l !== grst_prev) begin
        $display("[%0t] [GRST] spc_grst_l mudou para %b", $time, u_chip.tile0.spc_grst_l);
        grst_prev <= u_chip.tile0.spc_grst_l;
    end
end

// Requisicao chegando ao L15 (val=1 quando CVA6 envia IMISS/DMISS)
always @(posedge clk) begin
    if (rst_n && u_chip.tile0.transducer_l15_val)
        $display("[%0t] [L15IN] val=1 rqtype=%0d addr=0x%010X nc=%b ack=%b",
                 $time,
                 u_chip.tile0.transducer_l15_rqtype,
                 u_chip.tile0.transducer_l15_address,
                 u_chip.tile0.transducer_l15_nc,
                 u_chip.tile0.l15_transducer_ack);
end

// Resposta do L15 de volta ao CVA6
always @(posedge clk) begin
    if (rst_n && u_chip.tile0.l15_transducer_val)
        $display("[%0t] [L15OUT] val=1 rtype=%0d l2miss=%b",
                 $time,
                 u_chip.tile0.l15_transducer_returntype,
                 u_chip.tile0.l15_transducer_l2miss);
end

// Pipeline L15: S1/S2/S3 validos OU buffer/encoder ativos
always @(posedge clk) begin
    if (rst_n && (u_chip.tile0.l15.l15.pipeline.val_s1 ||
                  u_chip.tile0.l15.l15.pipeline.val_s2 ||
                  u_chip.tile0.l15.l15.pipeline.val_s3 ||
                  u_chip.tile0.l15.l15.noc1buffer_noc1encoder_req_val ||
                  u_chip.tile0.l15.l15.noc1encoder.sending))
        $display("[%0t] [L15PIPE] s1=%b s2=%b s3=%b stl1=%b stl2=%b stl3=%b noc1s3=%b noc1buf=%b enc=%b dmbr=%b snd=%b noc1avail=%0d homeidval=%b",
                 $time,
                 u_chip.tile0.l15.l15.pipeline.val_s1,
                 u_chip.tile0.l15.l15.pipeline.val_s2,
                 u_chip.tile0.l15.l15.pipeline.val_s3,
                 u_chip.tile0.l15.l15.pipeline.stall_s1,
                 u_chip.tile0.l15.l15.pipeline.stall_s2,
                 u_chip.tile0.l15.l15.pipeline.stall_s3,
                 u_chip.tile0.l15.l15.pipeline.noc1_req_val_s3,
                 u_chip.tile0.l15.l15.l15_noc1buffer_req_val,
                 u_chip.tile0.l15.l15.noc1buffer_noc1encoder_req_val,
                 u_chip.tile0.l15.l15.noc1encoder.dmbr_stall,
                 u_chip.tile0.l15.l15.noc1encoder.sending,
                 u_chip.tile0.l15.l15.pipeline.creditman_noc1_avail,
                 u_chip.tile0.l15.l15.pipeline.l15_noc1buffer_req_homeid_val);
end

// noc1encoder saída — dispara quando o encoder produz um flit
always @(posedge clk) begin
    if (rst_n && u_chip.tile0.l15.l15.noc1encoder.noc1encoder_noc1out_val)
        $display("[%0t] [NOC1ENC] flit=0x%016X state=%0d",
                 $time,
                 u_chip.tile0.l15.l15.noc1encoder.noc1encoder_noc1out_data,
                 u_chip.tile0.l15.l15.noc1encoder.flit_state);
end

// ------------------------------------------------------------
// Heartbeat: a cada 50 ciclos (e a cada 10 nos primeiros 500)
// ------------------------------------------------------------
integer cycle_count;
initial cycle_count = 0;

// Dump periódico a cada 500 ciclos: estado do noc1buffer e encoder
always @(posedge clk) begin
    if (rst_n && cycle_count % 500 == 1)
        $display("[%0t] [NOC1ST] c=%0d enc=%b snd=%b noc1out=%b bufval=%b dmbr=%b grst=%b",
                 $time, cycle_count,
                 u_chip.tile0.l15.l15.noc1buffer_noc1encoder_req_val,
                 u_chip.tile0.l15.l15.noc1encoder.sending,
                 u_chip.tile0.l15.l15.noc1encoder.noc1encoder_noc1out_val,
                 u_chip.tile0.l15.l15.l15_noc1buffer_req_val,
                 u_chip.tile0.l15.l15.noc1encoder.dmbr_stall,
                 u_chip.tile0.spc_grst_l);
end
always @(posedge clk) begin
    if (rst_n) begin
        cycle_count <= cycle_count + 1;

        // Granular nos primeiros 500 ciclos
        if (cycle_count < 500 && cycle_count % 10 == 0)
            $display("[%0t] c=%0d rst=%b noc1W=%b noc1E=%b axi_ar=%b axi_aw=%b rd=%0d wr=%0d",
                     $time, cycle_count,
                     u_chip.rst_n_inter_sync,
                     chip_noc1_valid,
                     u_chip.tile_0_0_out_E_noc1_valid,
                     m_axi_arvalid, m_axi_awvalid,
                     axi_rd_count, axi_wr_count);
        // Depois a cada 50
        else if (cycle_count >= 500 && cycle_count % 50 == 0)
            $display("[%0t] c=%0d noc1W=%b axi_ar=%b rd=%0d wr=%0d",
                     $time, cycle_count,
                     chip_noc1_valid,
                     m_axi_arvalid,
                     axi_rd_count, axi_wr_count);
    end
end

// ------------------------------------------------------------
// Verificação final
// ------------------------------------------------------------
initial begin
    repeat (RESET_CYCLES + SIM_CYCLES) @(posedge clk);

    $display("==================================================");
    $display("RESULTADO FINAL — %0d ciclos", RESET_CYCLES + SIM_CYCLES);
    $display("  Transacoes AXI4 leitura : %0d", axi_rd_count);
    $display("  Transacoes AXI4 escrita : %0d", axi_wr_count);
    $display("  NoC1 flits vistos       : %0d (primeiro=%b)", chip_noc1_valid, noc1_seen);
    $display("==================================================");

    if (axi_rd_count == 0 && axi_wr_count == 0) begin
        $display("FAIL: nenhum acesso AXI4 (cores nao acessaram memoria).");
        $finish;
    end

    if (axi_rd_count >= 1) begin
        $display("PASS: Dual-Core CVA6 acessou memoria via AXI4 leitura.");
    end else begin
        $display("PARCIAL: so escritas AXI4 detectadas (sem leituras).");
    end
    $finish;
end

endmodule
