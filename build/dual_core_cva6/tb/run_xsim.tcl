# =============================================================================
# run_xsim.tcl
# Executa a simulação dentro do Vivado (após projeto já criado)
#
# Uso no Vivado Tcl Console:
#   source run_xsim.tcl
# =============================================================================

# Compila e inicia a simulação
launch_simulation

# Adiciona todos os sinais da hierarquia ao waveform
add_wave_divider "--- Clock / Reset ---"
add_wave {{/tb_dual_core_cva6/clk}}
add_wave {{/tb_dual_core_cva6/rst_n}}

add_wave_divider "--- NoC0 tile0→tile1 (requisições) ---"
add_wave {{/tb_dual_core_cva6/t0_E_noc0_v}}
add_wave {{/tb_dual_core_cva6/t0_E_noc0}}
add_wave {{/tb_dual_core_cva6/t0_E_noc0_y}}

add_wave_divider "--- NoC0 tile1→tile0 ---"
add_wave {{/tb_dual_core_cva6/t1_W_noc0_v}}
add_wave {{/tb_dual_core_cva6/t1_W_noc0}}

add_wave_divider "--- NoC1 tile0→tile1 (respostas) ---"
add_wave {{/tb_dual_core_cva6/t0_E_noc1_v}}
add_wave {{/tb_dual_core_cva6/t0_E_noc1}}

add_wave_divider "--- NoC2 tile0→tile1 (acks) ---"
add_wave {{/tb_dual_core_cva6/t0_E_noc2_v}}
add_wave {{/tb_dual_core_cva6/t0_E_noc2}}

add_wave_divider "--- Contadores ---"
add_wave {{/tb_dual_core_cva6/noc0_pkts}}
add_wave {{/tb_dual_core_cva6/noc1_pkts}}
add_wave {{/tb_dual_core_cva6/noc2_pkts}}

# Executa 50 us (cobre reset + 2000 ciclos @ 100 MHz)
run 50us

puts ""
puts "Simulação concluída."
puts "Use: open_wave_database tb_dual_core_cva6.wdb  (para reabrir waveforms)"
