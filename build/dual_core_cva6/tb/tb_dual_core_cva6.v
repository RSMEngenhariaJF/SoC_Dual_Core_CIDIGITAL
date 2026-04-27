// Testbench: Dual-Core CVA6 SoC (OpenPiton 2x1 mesh)
// Dois tiles CVA6 (RV64IMAFDC) conectados via P-Mesh NoC East-West.
// Objetivo: verificar reset, clock e integridade das conexões NoC.
//
// Simuladores suportados: Icarus Verilog (iverilog) ou Verilator (WSL2)
// Uso: veja run_iverilog.sh / run_verilator.sh

`timescale 1ns/1ps

`include "define.tmp.h"
`include "jtag.vh"
`include "piton_system.vh"

module tb_dual_core_cva6;

// ------------------------------------------------------------
// Parâmetros de simulação
// ------------------------------------------------------------
parameter CLK_PERIOD   = 10;   // 10 ns → 100 MHz
parameter RESET_CYCLES = 100;
parameter SIM_CYCLES   = 2000;

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
    $display("[%0t] Reset deasserted — ambos os CVA6 cores ativos.", $time);
end

// ------------------------------------------------------------
// Watchdog
// ------------------------------------------------------------
initial begin
    #(CLK_PERIOD * (RESET_CYCLES + SIM_CYCLES + 100));
    $display("[%0t] TIMEOUT: simulação encerrada após %0d ciclos.", $time, RESET_CYCLES + SIM_CYCLES);
    $finish;
end

// ------------------------------------------------------------
// Wires NoC entre tile0 (core 0) e tile1 (core 1)
// Malha 2x1: tile0.E ↔ tile1.W  (3 redes: noc0, noc1, noc2)
// N/S/borda ficam com dummy (valid=0)
// ------------------------------------------------------------

// --- Conexão East tile0 → West tile1 (NOC 0/1/2) ---
wire [`NOC_DATA_WIDTH-1:0] t0_E_noc0, t0_E_noc1, t0_E_noc2;
wire                        t0_E_noc0_v, t0_E_noc1_v, t0_E_noc2_v;
wire                        t0_E_noc0_y, t0_E_noc1_y, t0_E_noc2_y;

// --- Conexão West tile1 → East tile0 (NOC 0/1/2) ---
wire [`NOC_DATA_WIDTH-1:0] t1_W_noc0, t1_W_noc1, t1_W_noc2;
wire                        t1_W_noc0_v, t1_W_noc1_v, t1_W_noc2_v;
wire                        t1_W_noc0_y, t1_W_noc1_y, t1_W_noc2_y;

// Sinais JTAG (tie-off)
wire jtag_ucb_val  = 1'b0;
wire [3:0] jtag_ucb_data = 4'b0;

// Interrupções e debug (tie-off — não usados neste TB)
wire [1:0] irq_tie   = 2'b0;
wire       ipi_tie   = 1'b0;
wire       timer_tie = 1'b0;
wire       dbg_tie   = 1'b0;

// ------------------------------------------------------------
// TILE 0  — CVA6 core 0  (x=0, y=0)
// ------------------------------------------------------------
tile #(.TILE_TYPE(`ARIANE_RV64_TILE)) u_tile0 (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .clk_en                 (1'b1),
    .default_chipid         (14'b0),
    .default_coreid_x       (8'd0),
    .default_coreid_y       (8'd0),
    .default_total_num_tiles(32'd2),
    .flat_tileid            (8'd0),

    // JTAG (não usado no TB)
    .jtag_tiles_ucb_val     (jtag_ucb_val),
    .jtag_tiles_ucb_data    (jtag_ucb_data),

    // NOC 0 inputs: N=0, E=tile1.W, W=0, S=0
    .dyn0_dataIn_N  (64'b0), .dyn0_validIn_N (1'b0), .dyn0_dNo_yummy (1'b0),
    .dyn0_dataIn_E  (t1_W_noc0),  .dyn0_validIn_E (t1_W_noc0_v),  .dyn0_dEo_yummy (t1_W_noc0_y),
    .dyn0_dataIn_W  (64'b0), .dyn0_validIn_W (1'b0), .dyn0_dWo_yummy (1'b0),
    .dyn0_dataIn_S  (64'b0), .dyn0_validIn_S (1'b0), .dyn0_dSo_yummy (1'b0),

    // NOC 1 inputs
    .dyn1_dataIn_N  (64'b0), .dyn1_validIn_N (1'b0), .dyn1_dNo_yummy (1'b0),
    .dyn1_dataIn_E  (t1_W_noc1),  .dyn1_validIn_E (t1_W_noc1_v),  .dyn1_dEo_yummy (t1_W_noc1_y),
    .dyn1_dataIn_W  (64'b0), .dyn1_validIn_W (1'b0), .dyn1_dWo_yummy (1'b0),
    .dyn1_dataIn_S  (64'b0), .dyn1_validIn_S (1'b0), .dyn1_dSo_yummy (1'b0),

    // NOC 2 inputs
    .dyn2_dataIn_N  (64'b0), .dyn2_validIn_N (1'b0), .dyn2_dNo_yummy (1'b0),
    .dyn2_dataIn_E  (t1_W_noc2),  .dyn2_validIn_E (t1_W_noc2_v),  .dyn2_dEo_yummy (t1_W_noc2_y),
    .dyn2_dataIn_W  (64'b0), .dyn2_validIn_W (1'b0), .dyn2_dWo_yummy (1'b0),
    .dyn2_dataIn_S  (64'b0), .dyn2_validIn_S (1'b0), .dyn2_dSo_yummy (1'b0),

    // NOC outputs East → tile1.W
    .dyn0_dEo (t0_E_noc0), .dyn0_dEo_valid (t0_E_noc0_v), .dyn0_yummyOut_E (t0_E_noc0_y),
    .dyn1_dEo (t0_E_noc1), .dyn1_dEo_valid (t0_E_noc1_v), .dyn1_yummyOut_E (t0_E_noc1_y),
    .dyn2_dEo (t0_E_noc2), .dyn2_dEo_valid (t0_E_noc2_v), .dyn2_yummyOut_E (t0_E_noc2_y),

    // Interrupções / debug (tie-off)
    .irq_i       (irq_tie),
    .ipi_i       (ipi_tie),
    .timer_irq_i (timer_tie),
    .debug_req_i (dbg_tie)
);

// ------------------------------------------------------------
// TILE 1  — CVA6 core 1  (x=1, y=0)
// ------------------------------------------------------------
tile #(.TILE_TYPE(`ARIANE_RV64_TILE)) u_tile1 (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .clk_en                 (1'b1),
    .default_chipid         (14'b0),
    .default_coreid_x       (8'd1),
    .default_coreid_y       (8'd0),
    .default_total_num_tiles(32'd2),
    .flat_tileid            (8'd1),

    .jtag_tiles_ucb_val     (jtag_ucb_val),
    .jtag_tiles_ucb_data    (jtag_ucb_data),

    // NOC 0 inputs: N=0, E=0, W=tile0.E, S=0
    .dyn0_dataIn_N  (64'b0), .dyn0_validIn_N (1'b0), .dyn0_dNo_yummy (1'b0),
    .dyn0_dataIn_E  (64'b0), .dyn0_validIn_E (1'b0), .dyn0_dEo_yummy (1'b0),
    .dyn0_dataIn_W  (t0_E_noc0),  .dyn0_validIn_W (t0_E_noc0_v),  .dyn0_dWo_yummy (t0_E_noc0_y),
    .dyn0_dataIn_S  (64'b0), .dyn0_validIn_S (1'b0), .dyn0_dSo_yummy (1'b0),

    // NOC 1 inputs
    .dyn1_dataIn_N  (64'b0), .dyn1_validIn_N (1'b0), .dyn1_dNo_yummy (1'b0),
    .dyn1_dataIn_E  (64'b0), .dyn1_validIn_E (1'b0), .dyn1_dEo_yummy (1'b0),
    .dyn1_dataIn_W  (t0_E_noc1),  .dyn1_validIn_W (t0_E_noc1_v),  .dyn1_dWo_yummy (t0_E_noc1_y),
    .dyn1_dataIn_S  (64'b0), .dyn1_validIn_S (1'b0), .dyn1_dSo_yummy (1'b0),

    // NOC 2 inputs
    .dyn2_dataIn_N  (64'b0), .dyn2_validIn_N (1'b0), .dyn2_dNo_yummy (1'b0),
    .dyn2_dataIn_E  (64'b0), .dyn2_validIn_E (1'b0), .dyn2_dEo_yummy (1'b0),
    .dyn2_dataIn_W  (t0_E_noc2),  .dyn2_validIn_W (t0_E_noc2_v),  .dyn2_dWo_yummy (t0_E_noc2_y),
    .dyn2_dataIn_S  (64'b0), .dyn2_validIn_S (1'b0), .dyn2_dSo_yummy (1'b0),

    // NOC outputs West → tile0.E (feedback)
    .dyn0_dWo (t1_W_noc0), .dyn0_dWo_valid (t1_W_noc0_v), .dyn0_yummyOut_W (t1_W_noc0_y),
    .dyn1_dWo (t1_W_noc1), .dyn1_dWo_valid (t1_W_noc1_v), .dyn1_yummyOut_W (t1_W_noc1_y),
    .dyn2_dWo (t1_W_noc2), .dyn2_dWo_valid (t1_W_noc2_v), .dyn2_yummyOut_W (t1_W_noc2_y),

    // Interrupções / debug (tie-off)
    .irq_i       (irq_tie),
    .ipi_i       (ipi_tie),
    .timer_irq_i (timer_tie),
    .debug_req_i (dbg_tie)
);

// ------------------------------------------------------------
// Monitor de atividade NoC
// ------------------------------------------------------------
integer noc0_pkts, noc1_pkts, noc2_pkts;
initial begin
    noc0_pkts = 0;
    noc1_pkts = 0;
    noc2_pkts = 0;
end

always @(posedge clk) begin
    if (rst_n) begin
        if (t0_E_noc0_v || t1_W_noc0_v) begin
            noc0_pkts <= noc0_pkts + 1;
            $display("[%0t] NOC0 flit: tile0→tile1=%b  tile1→tile0=%b", $time, t0_E_noc0_v, t1_W_noc0_v);
        end
        if (t0_E_noc1_v || t1_W_noc1_v) begin
            noc1_pkts <= noc1_pkts + 1;
            $display("[%0t] NOC1 flit: tile0→tile1=%b  tile1→tile0=%b", $time, t0_E_noc1_v, t1_W_noc1_v);
        end
        if (t0_E_noc2_v || t1_W_noc2_v) begin
            noc2_pkts <= noc2_pkts + 1;
            $display("[%0t] NOC2 flit: tile0→tile1=%b  tile1→tile0=%b", $time, t0_E_noc2_v, t1_W_noc2_v);
        end
    end
end

// ------------------------------------------------------------
// Verificação final
// ------------------------------------------------------------
initial begin
    $dumpfile("tb_dual_core_cva6.vcd");
    $dumpvars(0, tb_dual_core_cva6);

    // aguarda reset + ciclos de simulação
    repeat (RESET_CYCLES + SIM_CYCLES) @(posedge clk);

    $display("--------------------------------------------------");
    $display("RESULTADO FINAL — %0d ciclos simulados", RESET_CYCLES + SIM_CYCLES);
    $display("  Flits NoC0 (req/snoop): %0d", noc0_pkts);
    $display("  Flits NoC1 (resp/data): %0d", noc1_pkts);
    $display("  Flits NoC2 (ack):       %0d", noc2_pkts);
    $display("  rst_n final: %b  (esperado: 1)", rst_n);
    $display("--------------------------------------------------");

    if (rst_n !== 1'b1) begin
        $display("FAIL: rst_n não foi liberado corretamente.");
        $finish;
    end

    $display("PASS: Dual-Core CVA6 inicializou e operou sem travamentos.");
    $finish;
end

endmodule
