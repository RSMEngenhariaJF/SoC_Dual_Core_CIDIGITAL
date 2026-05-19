#!/usr/bin/env python3
"""
generate_diagrams.py
Gera dois diagramas de blocos em PNG:
  diagrama_soc.png  -- arquitetura do SoC OpenPiton 2x1 (tiles, NoC, AXI4)
  diagrama_uvm.png  -- estrutura do ambiente UVM (test, env, agents, DUT wrap)

Saida: doc/Teste leitura e escrita/
"""

import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR    = os.path.join(SCRIPT_DIR, "Teste leitura e escrita")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def box(ax, x, y, w, h, label, sublabel=None,
        fc="#DDEEFF", ec="#336699", lw=1.5,
        fontsize=9, bold=False, radius=0.015):
    patch = FancyBboxPatch(
        (x, y), w, h,
        boxstyle=f"round,pad=0,rounding_size={radius}",
        facecolor=fc, edgecolor=ec, linewidth=lw, zorder=2)
    ax.add_patch(patch)
    cy = y + h / 2
    weight = "bold" if bold else "normal"
    if sublabel:
        ax.text(x + w/2, cy + h*0.14, label,
                ha="center", va="center", fontsize=fontsize,
                fontweight=weight, color="#1a1a2e", zorder=3)
        ax.text(x + w/2, cy - h*0.18, sublabel,
                ha="center", va="center", fontsize=fontsize-1.5,
                color="#444466", zorder=3, style="italic")
    else:
        ax.text(x + w/2, cy, label,
                ha="center", va="center", fontsize=fontsize,
                fontweight=weight, color="#1a1a2e", zorder=3,
                multialignment="center")

def arrow(ax, x1, y1, x2, y2, color="#336699", lw=1.8, both=False):
    style = "<->" if both else "->"
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle=style, color=color,
                                lw=lw, mutation_scale=12),
                zorder=4)

def label_arrow(ax, x, y, text, fontsize=7.5, color="#444"):
    ax.text(x, y, text, ha="center", va="center",
            fontsize=fontsize, color=color, zorder=5,
            bbox=dict(fc="white", ec="none", pad=1))

# ===========================================================================
# DIAGRAMA 1 — SoC OpenPiton 2x1
# ===========================================================================
def draw_soc():
    fig, ax = plt.subplots(figsize=(14, 11))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 11)
    ax.axis("off")
    fig.patch.set_facecolor("#F8F9FA")

    # --- Titulo ---
    ax.text(7, 10.65, "Arquitetura do SoC OpenPiton 2×1 — CVA6 RV64GC",
            ha="center", va="center", fontsize=13, fontweight="bold", color="#1a1a2e")
    ax.text(7, 10.35, "100 MHz | SRAM 256 KB | NoC P-Mesh 3 redes | xsim 2025.1",
            ha="center", va="center", fontsize=8.5, color="#555577")

    # --- Container SoC ---
    soc = FancyBboxPatch((0.3, 0.3), 13.4, 9.8,
        boxstyle="round,pad=0,rounding_size=0.05",
        facecolor="#EEF2FF", edgecolor="#6677AA", linewidth=2, zorder=1)
    ax.add_patch(soc)
    ax.text(0.65, 9.85, "OpenPiton SoC", fontsize=8, color="#6677AA",
            fontweight="bold", va="center")

    # ================================================================
    # TILE 0
    # ================================================================
    tile_fc  = "#FFFFFF"
    tile_ec  = "#2255AA"

    # Container Tile 0
    t0 = FancyBboxPatch((0.6, 3.9), 5.8, 5.7,
        boxstyle="round,pad=0,rounding_size=0.04",
        facecolor=tile_fc, edgecolor=tile_ec, linewidth=1.8, zorder=1)
    ax.add_patch(t0)
    ax.text(3.5, 9.4, "Tile 0", ha="center", fontsize=10,
            fontweight="bold", color="#2255AA")

    # CVA6 Core box Tile0
    box(ax, 0.9, 7.5, 5.2, 1.6,
        "CVA6 Core — Hart 0  (RV64GC + M-ext)",
        "IF → ID → IS → EX → WB → COMMIT   |   ROB: 8 entries, 2 commit ports",
        fc="#CCE5FF", ec="#2255AA", lw=1.5, fontsize=8.5, bold=True, radius=0.03)

    # L1 ICache Tile0
    box(ax, 0.9, 6.6, 2.4, 0.75,
        "L1 ICache",
        "16 KB | 4-way | linha 32 B",
        fc="#E8F4FD", ec="#5588BB", fontsize=8)

    # L1 DCache + store_buffer Tile0
    box(ax, 3.5, 6.6, 2.6, 0.75,
        "L1 DCache + store_buffer",
        "write-through | 4 entradas spec",
        fc="#E8F4FD", ec="#5588BB", fontsize=8)

    # L1.5 TRI Tile0
    box(ax, 0.9, 5.7, 5.2, 0.75,
        "L1.5 TRI (L15ADAP)",
        "8 KB | 4-way | MESI | adaptador L15 → NoC",
        fc="#D6EAF8", ec="#3377AA", fontsize=8, bold=False)

    # NoC interface Tile0
    box(ax, 0.9, 4.85, 5.2, 0.65,
        "Interface NoC P-Mesh",
        "encoder/decoder | flits 64-bit",
        fc="#D5D8DC", ec="#5D6D7E", fontsize=7.8)

    # Setas internas Tile0
    arrow(ax, 3.5, 7.5,  3.5, 7.35, both=True)   # core <-> icache/dcache
    arrow(ax, 2.1, 6.6,  2.1, 6.45, both=True)   # icache <-> l1.5
    arrow(ax, 4.8, 6.6,  4.8, 6.45, both=True)   # dcache <-> l1.5
    arrow(ax, 3.5, 5.7,  3.5, 5.5,  both=True)   # l1.5 <-> noc if
    ax.annotate("", xy=(3.5, 7.35), xytext=(3.5, 7.5),
                arrowprops=dict(arrowstyle="->", color="#2255AA", lw=1.2, mutation_scale=10))

    # ================================================================
    # TILE 1
    # ================================================================
    # Container Tile 1
    t1 = FancyBboxPatch((7.6, 3.9), 5.8, 5.7,
        boxstyle="round,pad=0,rounding_size=0.04",
        facecolor=tile_fc, edgecolor=tile_ec, linewidth=1.8, zorder=1)
    ax.add_patch(t1)
    ax.text(10.5, 9.4, "Tile 1", ha="center", fontsize=10,
            fontweight="bold", color="#2255AA")

    # CVA6 Core box Tile1
    box(ax, 7.9, 7.5, 5.2, 1.6,
        "CVA6 Core — Hart 1  (RV64GC + M-ext)",
        "IF → ID → IS → EX → WB → COMMIT   |   ROB: 8 entries, 2 commit ports",
        fc="#CCE5FF", ec="#2255AA", lw=1.5, fontsize=8.5, bold=True, radius=0.03)

    # L1 ICache Tile1
    box(ax, 7.9, 6.6, 2.4, 0.75,
        "L1 ICache",
        "16 KB | 4-way | linha 32 B",
        fc="#E8F4FD", ec="#5588BB", fontsize=8)

    # L1 DCache + store_buffer Tile1
    box(ax, 10.5, 6.6, 2.6, 0.75,
        "L1 DCache + store_buffer",
        "write-through | 4 entradas spec",
        fc="#E8F4FD", ec="#5588BB", fontsize=8)

    # L1.5 TRI Tile1
    box(ax, 7.9, 5.7, 5.2, 0.75,
        "L1.5 TRI (L15ADAP)",
        "8 KB | 4-way | MESI | adaptador L15 → NoC",
        fc="#D6EAF8", ec="#3377AA", fontsize=8)

    # NoC interface Tile1
    box(ax, 7.9, 4.85, 5.2, 0.65,
        "Interface NoC P-Mesh",
        "encoder/decoder | flits 64-bit",
        fc="#D5D8DC", ec="#5D6D7E", fontsize=7.8)

    # Setas internas Tile1
    arrow(ax, 10.5, 7.5,  10.5, 7.35, both=True)
    arrow(ax, 9.1,  6.6,   9.1, 6.45, both=True)
    arrow(ax, 11.8, 6.6,  11.8, 6.45, both=True)
    arrow(ax, 10.5, 5.7,  10.5, 5.5,  both=True)

    # ================================================================
    # NoC P-Mesh (3 redes)
    # ================================================================
    box(ax, 0.6, 3.15, 12.8, 0.60,
        "NoC P-Mesh   —   3 redes de interconexão compartilhadas",
        "NoC1: requisições (store/load req)   |   NoC2: respostas (fill, ack)   |   NoC3: write-back",
        fc="#FEF9E7", ec="#D4AC0D", lw=2, fontsize=8.5, bold=True, radius=0.02)

    # Setas Tile0 → NoC
    arrow(ax, 3.5, 4.85, 3.5, 3.75, both=True, color="#D4AC0D")
    # Setas Tile1 → NoC
    arrow(ax, 10.5, 4.85, 10.5, 3.75, both=True, color="#D4AC0D")

    # ================================================================
    # noc_axi4_bridge
    # ================================================================
    box(ax, 3.5, 2.35, 7.0, 0.65,
        "noc_axi4_bridge",
        "converte P-Mesh flits → transações AXI4 (AR/AW/W/R/B)",
        fc="#FDEBD0", ec="#CA6F1E", lw=1.8, fontsize=8.5, bold=True, radius=0.02)

    arrow(ax, 7.0, 3.15, 7.0, 3.0,  both=True, color="#CA6F1E")

    # ================================================================
    # AXI4 SRAM
    # ================================================================
    box(ax, 1.5, 0.55, 11.0, 1.65,
        "AXI4 SRAM  —  Memória Principal Compartilhada",
        "256 KB | 512 bits por beat (len=0) | latência ~13 ciclos\n"
        "BASE=0x80000000  |  código: 0x000-0x0FF  |  dados Hart0: 0x1000-0x1010  |  dados Hart1: 0x1020-0x1030\n"
        "tohost_pass: 0x8000FF50  |  tohost_fail: 0x8000FF58",
        fc="#EAFAF1", ec="#1E8449", lw=2, fontsize=8.2, bold=True, radius=0.02)

    arrow(ax, 7.0, 2.35, 7.0, 2.2,  both=True, color="#1E8449")

    # ================================================================
    # Legenda nota xsim
    # ================================================================
    note = FancyBboxPatch((0.6, 0.32), 12.8, 0.18,
        boxstyle="round,pad=0,rounding_size=0.02",
        facecolor="#FFF3CD", edgecolor="#856404", linewidth=1, zorder=2)
    ax.add_patch(note)
    ax.text(7, 0.41,
            "xsim 2025.1: store_buffer stub (ifndef XSIM) força data_req=0 → writes não chegam ao AXI4 "
            "| LW/LD crasham o kernel (D-cache wt_dcache_ctrl.sv:95)",
            ha="center", va="center", fontsize=7.2, color="#856404", zorder=3)

    plt.tight_layout(pad=0.2)
    path = os.path.join(OUT_DIR, "diagrama_soc.png")
    fig.savefig(path, dpi=180, bbox_inches="tight",
                facecolor=fig.get_facecolor())
    plt.close(fig)
    print(f"SoC:  {path}")


# ===========================================================================
# DIAGRAMA 2 — Ambiente UVM
# ===========================================================================
def draw_uvm():
    fig, ax = plt.subplots(figsize=(14, 13))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 13)
    ax.axis("off")
    fig.patch.set_facecolor("#F8F9FA")

    ax.text(7, 12.65, "Estrutura do Ambiente UVM — OpenPiton CVA6 Dual-Core",
            ha="center", va="center", fontsize=13, fontweight="bold", color="#1a1a2e")
    ax.text(7, 12.35, "UVM 1.2 (xlnx_uvm_package) | Vivado xsim 2025.1 | boot_rw.hex",
            ha="center", va="center", fontsize=8.5, color="#555577")

    # ================================================================
    # Container xsim
    # ================================================================
    outer = FancyBboxPatch((0.3, 0.3), 13.4, 11.8,
        boxstyle="round,pad=0,rounding_size=0.05",
        facecolor="#F2F3F4", edgecolor="#7F8C8D", linewidth=2, zorder=1)
    ax.add_patch(outer)
    ax.text(0.6, 11.88, "Vivado xsim 2025.1", fontsize=7.5,
            color="#7F8C8D", fontweight="bold")

    # ================================================================
    # boot_rw.hex (arquivo externo)
    # ================================================================
    box(ax, 0.6, 10.8, 3.2, 0.85,
        "boot_rw.hex",
        "1040 words × 32-bit\ngerado por build_rw_test.py",
        fc="#FEF9E7", ec="#D4AC0D", lw=1.8, fontsize=8, bold=True, radius=0.03)

    arrow(ax, 2.2, 10.8, 4.3, 10.45, color="#D4AC0D")
    label_arrow(ax, 3.1, 10.65, "$readmemh")

    # run_rw.tcl
    box(ax, 0.6, 9.7, 3.2, 0.85,
        "run_rw.tcl",
        "UVM_RUN_BINARY_OVERRIDE\n→ redireciona boot.hex",
        fc="#FEF9E7", ec="#D4AC0D", lw=1.5, fontsize=8, bold=False, radius=0.03)

    arrow(ax, 2.2, 9.7, 4.3, 9.85, color="#D4AC0D")

    # ================================================================
    # TEST
    # ================================================================
    box(ax, 4.0, 10.1, 9.5, 0.95,
        "uvmt_opc_asm_test_c   [TEST]",
        "UVM_TESTNAME=uvmt_opc_asm_test_c | seleciona sequencia | carrega binario | timeout=5000000",
        fc="#D5E8D4", ec="#267238", lw=2, fontsize=8.5, bold=True, radius=0.03)

    arrow(ax, 8.75, 10.1, 8.75, 9.8, color="#267238")

    # ================================================================
    # ENV container
    # ================================================================
    env = FancyBboxPatch((4.0, 5.5), 9.5, 4.4,
        boxstyle="round,pad=0,rounding_size=0.04",
        facecolor="#EBF5FB", edgecolor="#2E86C1", linewidth=1.8, zorder=1)
    ax.add_patch(env)
    ax.text(4.25, 9.72, "uvmt_opc_env   [ENV]   — 1×1 tiles | iss=0 | coh=1 | cov=1",
            fontsize=8.5, color="#2E86C1", fontweight="bold", va="center")

    # --- Agent: clk_rst ---
    box(ax, 4.2, 8.3, 3.8, 1.0,
        "clk_rst_agent",
        "driver: clock 10ns (100 MHz)\nrst_n=0 por 20 ciclos → deassert @t=200ns",
        fc="#D6EAF8", ec="#2980B9", fontsize=7.8, radius=0.025)

    # --- Agent: noc ---
    box(ax, 8.3, 8.3, 2.3, 1.0,
        "noc_agent",
        "monitor: NOC1_FIRST\n(flits de requisição NoC)",
        fc="#D6EAF8", ec="#2980B9", fontsize=7.8, radius=0.025)

    # --- Agent: l15_tri ---
    box(ax, 10.9, 8.3, 2.4, 1.0,
        "l15_tri_agent",
        "monitor: L15ADAP\n(REQ/RTRN/IFILL)",
        fc="#D6EAF8", ec="#2980B9", fontsize=7.8, radius=0.025)

    # --- Agent: status ---
    box(ax, 4.2, 7.05, 3.8, 1.0,
        "status_agent",
        "monitor: good_trap / bad_trap\n→ 'HIT GOOD TRAP Tile 0'",
        fc="#D6EAF8", ec="#2980B9", fontsize=7.8, radius=0.025)

    # --- Sequencia ---
    box(ax, 8.3, 7.05, 4.9, 1.0,
        "uvmt_opc_asm_test_seq   [SEQUENCE]",
        "aguarda execucao DUT | aplica clock+reset\n→ run.tcl: run -all",
        fc="#EBF5FB", ec="#2E86C1", fontsize=7.8, radius=0.025)

    # --- Scoreboard ---
    box(ax, 4.2, 5.75, 9.0, 1.0,
        "uvmt_opc_scoreboard   [SCOREBOARD]",
        "conta GOOD_TRAP por tile | finish_mask=0x7FFF\n"
        "Completados=0x1 / Esperados=0x1 @cyc=397  →  RESULTADO: PASSOU",
        fc="#D5F5E3", ec="#1E8449", lw=1.8, fontsize=8, bold=True, radius=0.025)

    # Setas dentro do env
    arrow(ax, 6.1,  9.72, 6.1,  9.3,  color="#2E86C1")
    arrow(ax, 9.4,  9.72, 9.4,  9.3,  color="#2E86C1")
    arrow(ax, 12.1, 9.72, 12.1, 9.3,  color="#2E86C1")
    arrow(ax, 6.1,  8.3,  6.1,  8.05, color="#2E86C1")
    arrow(ax, 8.75, 8.3,  8.75, 8.05, color="#2E86C1")

    # ================================================================
    # DUT WRAP container
    # ================================================================
    wrap = FancyBboxPatch((0.5, 0.5), 12.9, 4.85,
        boxstyle="round,pad=0,rounding_size=0.04",
        facecolor="#FDFEFE", edgecolor="#884EA0", linewidth=2, zorder=1)
    ax.add_patch(wrap)
    ax.text(0.75, 5.18,
            "uvmt_opc_dut_wrap.sv   [DUT WRAP + MONITORES CUSTOMIZADOS]",
            fontsize=8.5, color="#884EA0", fontweight="bold", va="center")

    # --- DUT OpenPiton ---
    box(ax, 0.7, 2.8, 5.5, 2.2,
        "OpenPiton DUT",
        "chip_top.v → 2× Tile CVA6\n"
        "→ NoC P-Mesh → noc_axi4_bridge\n"
        "→ AXI4 SRAM (boot_rw.hex)",
        fc="#E8DAEF", ec="#7D3C98", lw=1.8, fontsize=8, bold=True, radius=0.03)

    # --- Monitor H0/H1 ---
    box(ax, 6.5, 3.9, 3.0, 1.1,
        "H0_COMMIT / H1_COMMIT",
        "always @(posedge clk)\nlog PC + ciclo por commit",
        fc="#FDEBD0", ec="#CA6F1E", fontsize=7.8, radius=0.025)

    # --- Monitor SB0/SB1 ---
    box(ax, 9.8, 3.9, 3.5, 1.1,
        "SB0_STORE / SB1_STORE",
        "store_buffer.commit_i\n→ addr[55:0] + data[63:0]",
        fc="#FDEBD0", ec="#CA6F1E", fontsize=7.8, radius=0.025)

    # --- Monitor AXI_AR ---
    box(ax, 6.5, 2.65, 3.0, 1.0,
        "AXI_AR monitor",
        "m_axi_arvalid & arready\nINST (< 0x80001000) / DATA",
        fc="#FDEBD0", ec="#CA6F1E", fontsize=7.8, radius=0.025)

    # --- STORE_COMMIT / good_trap ---
    box(ax, 9.8, 2.65, 3.5, 1.0,
        "STORE_COMMIT  →  good_trap",
        "commit_i & addr==0x8000FF50\n→ seta good_trap, drain 25 ciclos",
        fc="#FADBD8", ec="#C0392B", lw=1.8, fontsize=7.8, bold=True, radius=0.025)

    # Mapa de memoria
    box(ax, 0.7, 0.65, 5.5, 1.9,
        "Mapa de Memória  (SRAM BASE=0x80000000)",
        "0x000000  código: _start / compute / store / verify / pass\n"
        "0x001000  Hart0 data: ADD=16  SUB=4  MUL=60  AND=2  OR=14\n"
        "0x001020  Hart1 data: ADD=12  SUB=6  MUL=27  AND=1  OR=11\n"
        "0x00FF50  tohost_pass (escrita 1 → GOOD TRAP)",
        fc="#E9F7EF", ec="#1E8449", fontsize=7.5, radius=0.025)

    # Setas DUT → Monitores
    arrow(ax, 6.0,  4.4,  6.5,  4.4,  color="#7D3C98")
    arrow(ax, 6.0,  3.5,  6.5,  3.5,  color="#7D3C98")
    arrow(ax, 9.5,  4.4,  9.8,  4.4,  color="#CA6F1E")
    arrow(ax, 9.5,  3.1,  9.8,  3.1,  color="#C0392B")

    # Seta DUT wrap → Scoreboard (status)
    arrow(ax, 11.5, 5.35, 11.5, 5.5, color="#884EA0")
    label_arrow(ax, 12.1, 5.42, "good_trap", fontsize=7)

    # Seta ENV → DUT Wrap
    arrow(ax, 7.0, 5.5, 7.0, 5.35, color="#2E86C1")

    # ================================================================
    # Legenda de cores
    # ================================================================
    legend_items = [
        ("#D5E8D4", "#267238", "Test"),
        ("#D6EAF8", "#2980B9", "Agentes UVM"),
        ("#D5F5E3", "#1E8449", "Scoreboard"),
        ("#E8DAEF", "#7D3C98", "DUT"),
        ("#FDEBD0", "#CA6F1E", "Monitores custom"),
        ("#FADBD8", "#C0392B", "GOOD TRAP"),
        ("#FEF9E7", "#D4AC0D", "Arquivos / TCL"),
    ]
    lx = 0.5
    for fc, ec, lbl in legend_items:
        rect = FancyBboxPatch((lx, 12.05), 0.28, 0.22,
            boxstyle="round,pad=0,rounding_size=0.01",
            facecolor=fc, edgecolor=ec, linewidth=1.2, zorder=3)
        ax.add_patch(rect)
        ax.text(lx + 0.32, 12.16, lbl, fontsize=7.5, va="center",
                color="#1a1a2e", zorder=4)
        lx += len(lbl) * 0.13 + 0.65

    plt.tight_layout(pad=0.2)
    path = os.path.join(OUT_DIR, "diagrama_uvm.png")
    fig.savefig(path, dpi=180, bbox_inches="tight",
                facecolor=fig.get_facecolor())
    plt.close(fig)
    print(f"UVM:  {path}")


# ===========================================================================
# MAIN
# ===========================================================================
if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    draw_soc()
    draw_uvm()
    print("Diagramas gerados com sucesso.")
