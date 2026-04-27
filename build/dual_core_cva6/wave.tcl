# ============================================================
# wave.tcl — waveform configuration for tb_dual_core_cva6
# ============================================================

# Log all signals to the waveform database
log_wave -recursive *

# -------------------- Clock / Reset -------------------------
add_wave_divider "Clock / Reset"
add_wave /tb_dual_core_cva6/clk
add_wave /tb_dual_core_cva6/rst_n

# -------------------- NoC0 tile0 → tile1 -------------------
add_wave_divider "NoC0  tile0->tile1 (requests)"
add_wave /tb_dual_core_cva6/t0_E_noc0_v
add_wave /tb_dual_core_cva6/t0_E_noc0
add_wave /tb_dual_core_cva6/t0_E_noc0_y

# -------------------- NoC0 tile1 → tile0 -------------------
add_wave_divider "NoC0  tile1->tile0"
add_wave /tb_dual_core_cva6/t1_W_noc0_v
add_wave /tb_dual_core_cva6/t1_W_noc0
add_wave /tb_dual_core_cva6/t1_W_noc0_y

# -------------------- NoC1 (responses) ----------------------
add_wave_divider "NoC1  tile0->tile1 (responses)"
add_wave /tb_dual_core_cva6/t0_E_noc1_v
add_wave /tb_dual_core_cva6/t0_E_noc1
add_wave /tb_dual_core_cva6/t0_E_noc1_y

add_wave_divider "NoC1  tile1->tile0"
add_wave /tb_dual_core_cva6/t1_W_noc1_v
add_wave /tb_dual_core_cva6/t1_W_noc1
add_wave /tb_dual_core_cva6/t1_W_noc1_y

# -------------------- NoC2 (acks) ---------------------------
add_wave_divider "NoC2  tile0->tile1 (acks)"
add_wave /tb_dual_core_cva6/t0_E_noc2_v
add_wave /tb_dual_core_cva6/t0_E_noc2
add_wave /tb_dual_core_cva6/t0_E_noc2_y

add_wave_divider "NoC2  tile1->tile0"
add_wave /tb_dual_core_cva6/t1_W_noc2_v
add_wave /tb_dual_core_cva6/t1_W_noc2
add_wave /tb_dual_core_cva6/t1_W_noc2_y

# -------------------- Flit counters -------------------------
add_wave_divider "Flit counters"
add_wave /tb_dual_core_cva6/noc0_pkts
add_wave /tb_dual_core_cva6/noc1_pkts
add_wave /tb_dual_core_cva6/noc2_pkts

# ===================== RUN ==================================
run all

# ===================== DEBUG ================================
puts "Simulation finished at time [current_time]"
