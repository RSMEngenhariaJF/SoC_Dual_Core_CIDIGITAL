# =============================================================================
# wave.tcl  -  OpenPiton+CVA6 UVM 2x1  [Vivado XSim GUI]
#
# Hierarquia de instâncias (chip.v integrado):
#   /uvmt_opc_tb/                    — testbench top
#   /uvmt_opc_tb/dut_wrap/           — DUT wrapper
#   /uvmt_opc_tb/dut_wrap/u_chip/    — chip.v (2x1 tiles)
#   /uvmt_opc_tb/dut_wrap/u_adapter/ — protocol_adapter
#   /uvmt_opc_tb/dut_wrap/u_bridge/  — noc_axi4_bridge
#   /uvmt_opc_tb/dut_wrap/u_sram/    — axi4_sram_model
#
# Todos os add_wave usam catch para não abortar em sinais inexistentes.
# =============================================================================

catch {remove_wave -of [get_waves *] -quiet}

# --- Raízes de hierarquia ----------------------------------------------------
set TB    "/uvmt_opc_tb"
set DUT   "/uvmt_opc_tb/dut_wrap"
set CHIP  "/uvmt_opc_tb/dut_wrap/u_chip"
set T0    "/uvmt_opc_tb/dut_wrap/u_chip/tile0"
set L15P  "/uvmt_opc_tb/dut_wrap/u_chip/tile0/l15/l15/pipeline"
set L15E  "/uvmt_opc_tb/dut_wrap/u_chip/tile0/l15/l15/noc1encoder"
set BRG   "/uvmt_opc_tb/dut_wrap/u_bridge"

catch {create_wave_config}

# =============================================================================
# GRUPO 1: Clock / Reset
# =============================================================================
catch {add_wave_group "Clocks_Resets"}
catch {add_wave -into Clocks_Resets -radix bin  ${TB}/clk_rst_if/clk}
catch {add_wave -into Clocks_Resets -radix bin  ${TB}/clk_rst_if/rst_n}
catch {add_wave -into Clocks_Resets -radix bin  ${CHIP}/rst_n_inter_sync}
catch {add_wave -into Clocks_Resets -radix bin  ${T0}/spc_grst_l}

# =============================================================================
# GRUPO 2: Status / Trap
# =============================================================================
catch {add_wave_group "UVM_Status"}
catch {add_wave -into UVM_Status -radix bin   ${TB}/status_if/good_trap}
catch {add_wave -into UVM_Status -radix bin   ${TB}/status_if/bad_trap}
catch {add_wave -into UVM_Status -radix udec  ${TB}/status_if/cycle_count}
catch {add_wave -into UVM_Status -radix bin   ${DUT}/tohost_addr_latch}
catch {add_wave -into UVM_Status -radix hex   ${DUT}/m_axi_awaddr}

# =============================================================================
# GRUPO 3: NoC1 — Requisições saindo do chip
# =============================================================================
catch {add_wave_group "NoC1_Out"}
catch {add_wave -into NoC1_Out -radix bin  ${TB}/noc_if/noc1_out_valid}
catch {add_wave -into NoC1_Out -radix bin  ${TB}/noc_if/noc1_out_ready}
catch {add_wave -into NoC1_Out -radix hex  ${TB}/noc_if/noc1_out_data}
catch {add_wave -into NoC1_Out -radix bin  ${DUT}/chip_noc1_valid}
catch {add_wave -into NoC1_Out -radix bin  ${DUT}/chip_noc1_yummy}
catch {add_wave -into NoC1_Out -radix hex  ${DUT}/chip_noc1_data}
catch {add_wave -into NoC1_Out -radix bin  ${CHIP}/tile_0_0_out_E_noc1_valid}

# =============================================================================
# GRUPO 4: NoC2 — Respostas chegando ao chip
# =============================================================================
catch {add_wave_group "NoC2_In"}
catch {add_wave -into NoC2_In -radix bin  ${TB}/noc_if/noc2_in_valid}
catch {add_wave -into NoC2_In -radix bin  ${TB}/noc_if/noc2_in_ready}
catch {add_wave -into NoC2_In -radix hex  ${TB}/noc_if/noc2_in_data}
catch {add_wave -into NoC2_In -radix bin  ${DUT}/chip_noc2_valid}
catch {add_wave -into NoC2_In -radix bin  ${DUT}/chip_noc2_yummy}
catch {add_wave -into NoC2_In -radix hex  ${DUT}/chip_noc2_data}

# =============================================================================
# GRUPO 5: NoC3 — Writebacks WT
# =============================================================================
catch {add_wave_group "NoC3_WT"}
catch {add_wave -into NoC3_WT -radix bin  ${TB}/noc_if/noc3_out_valid}
catch {add_wave -into NoC3_WT -radix hex  ${TB}/noc_if/noc3_out_data}
catch {add_wave -into NoC3_WT -radix bin  ${DUT}/chip_noc3_valid}
catch {add_wave -into NoC3_WT -radix hex  ${DUT}/chip_noc3_data}

# =============================================================================
# GRUPO 6: Bridge val/rdy interno (adapter ↔ bridge)
# =============================================================================
catch {add_wave_group "Bridge_ValRdy"}
catch {add_wave -into Bridge_ValRdy -radix bin  ${DUT}/bridge_req_valid}
catch {add_wave -into Bridge_ValRdy -radix bin  ${DUT}/bridge_req_rdy}
catch {add_wave -into Bridge_ValRdy -radix hex  ${DUT}/bridge_req_data}
catch {add_wave -into Bridge_ValRdy -radix bin  ${DUT}/bridge_resp_valid}
catch {add_wave -into Bridge_ValRdy -radix bin  ${DUT}/bridge_resp_rdy}
catch {add_wave -into Bridge_ValRdy -radix hex  ${DUT}/bridge_resp_data}

# =============================================================================
# GRUPO 7: AXI4 AR + R (leitura)
# =============================================================================
catch {add_wave_group "AXI4_Read"}
catch {add_wave -into AXI4_Read -radix hex   ${DUT}/m_axi_araddr}
catch {add_wave -into AXI4_Read -radix udec  ${DUT}/m_axi_arlen}
catch {add_wave -into AXI4_Read -radix bin   ${DUT}/m_axi_arvalid}
catch {add_wave -into AXI4_Read -radix bin   ${DUT}/m_axi_arready}
catch {add_wave -into AXI4_Read -radix hex   ${DUT}/m_axi_rdata}
catch {add_wave -into AXI4_Read -radix bin   ${DUT}/m_axi_rlast}
catch {add_wave -into AXI4_Read -radix bin   ${DUT}/m_axi_rvalid}
catch {add_wave -into AXI4_Read -radix bin   ${DUT}/m_axi_rready}
catch {add_wave -into AXI4_Read -radix udec  ${DUT}/m_axi_rresp}

# =============================================================================
# GRUPO 8: AXI4 AW + W + B (escrita)
# =============================================================================
catch {add_wave_group "AXI4_Write"}
catch {add_wave -into AXI4_Write -radix hex   ${DUT}/m_axi_awaddr}
catch {add_wave -into AXI4_Write -radix udec  ${DUT}/m_axi_awlen}
catch {add_wave -into AXI4_Write -radix bin   ${DUT}/m_axi_awvalid}
catch {add_wave -into AXI4_Write -radix bin   ${DUT}/m_axi_awready}
catch {add_wave -into AXI4_Write -radix hex   ${DUT}/m_axi_wdata}
catch {add_wave -into AXI4_Write -radix hex   ${DUT}/m_axi_wstrb}
catch {add_wave -into AXI4_Write -radix bin   ${DUT}/m_axi_wlast}
catch {add_wave -into AXI4_Write -radix bin   ${DUT}/m_axi_wvalid}
catch {add_wave -into AXI4_Write -radix bin   ${DUT}/m_axi_wready}
catch {add_wave -into AXI4_Write -radix udec  ${DUT}/m_axi_bresp}
catch {add_wave -into AXI4_Write -radix bin   ${DUT}/m_axi_bvalid}
catch {add_wave -into AXI4_Write -radix bin   ${DUT}/m_axi_bready}

# =============================================================================
# GRUPO 9: L1.5 TRI — Requisição CVA6 → L15
# =============================================================================
catch {add_wave_group "L15_TRI_Req"}
catch {add_wave -into L15_TRI_Req -radix bin  ${TB}/l15_tri_if/transducer_l15_val}
catch {add_wave -into L15_TRI_Req -radix hex  ${TB}/l15_tri_if/transducer_l15_reqtype}
catch {add_wave -into L15_TRI_Req -radix hex  ${TB}/l15_tri_if/transducer_l15_address}
catch {add_wave -into L15_TRI_Req -radix bin  ${TB}/l15_tri_if/transducer_l15_nc}
catch {add_wave -into L15_TRI_Req -radix bin  ${TB}/l15_tri_if/transducer_l15_ack}

# =============================================================================
# GRUPO 10: L1.5 TRI — Resposta L15 → CVA6
# =============================================================================
catch {add_wave_group "L15_TRI_Rsp"}
catch {add_wave -into L15_TRI_Rsp -radix bin  ${TB}/l15_tri_if/l15_transducer_val}
catch {add_wave -into L15_TRI_Rsp -radix hex  ${TB}/l15_tri_if/l15_transducer_returntype}
catch {add_wave -into L15_TRI_Rsp -radix hex  ${TB}/l15_tri_if/l15_transducer_returndata_0}
catch {add_wave -into L15_TRI_Rsp -radix hex  ${TB}/l15_tri_if/l15_transducer_returndata_1}
catch {add_wave -into L15_TRI_Rsp -radix bin  ${TB}/l15_tri_if/l15_transducer_ack}
catch {add_wave -into L15_TRI_Rsp -radix bin  ${TB}/l15_tri_if/l15_transducer_inval_valid}
catch {add_wave -into L15_TRI_Rsp -radix hex  ${TB}/l15_tri_if/l15_transducer_inval_address}
catch {add_wave -into L15_TRI_Rsp -radix bin  ${TB}/l15_tri_if/l15_transducer_inval_icache_all_way}
catch {add_wave -into L15_TRI_Rsp -radix bin  ${TB}/l15_tri_if/l15_transducer_inval_dcache_all_way}

# =============================================================================
# GRUPO 11: L15 Pipeline interno — tile0
# =============================================================================
catch {add_wave_group "L15_Pipeline"}
catch {add_wave -into L15_Pipeline -radix bin   ${L15P}/val_s1}
catch {add_wave -into L15_Pipeline -radix bin   ${L15P}/val_s2}
catch {add_wave -into L15_Pipeline -radix bin   ${L15P}/val_s3}
catch {add_wave -into L15_Pipeline -radix bin   ${L15P}/stall_s1}
catch {add_wave -into L15_Pipeline -radix bin   ${L15P}/stall_s2}
catch {add_wave -into L15_Pipeline -radix bin   ${L15P}/stall_s3}
catch {add_wave -into L15_Pipeline -radix bin   ${L15P}/noc1_req_val_s3}
catch {add_wave -into L15_Pipeline -radix udec  ${L15P}/creditman_noc1_avail}

# =============================================================================
# GRUPO 12: L15 NoC1 Encoder — tile0
# =============================================================================
catch {add_wave_group "L15_Encoder"}
catch {add_wave -into L15_Encoder -radix bin   ${L15E}/sending}
catch {add_wave -into L15_Encoder -radix bin   ${L15E}/dmbr_stall}
catch {add_wave -into L15_Encoder -radix udec  ${L15E}/flit_state}
catch {add_wave -into L15_Encoder -radix bin   ${L15E}/noc1encoder_noc1out_val}
catch {add_wave -into L15_Encoder -radix hex   ${L15E}/noc1encoder_noc1out_data}
catch {add_wave -into L15_Encoder -radix bin   ${T0}/l15/l15/l15_noc1buffer_req_val}
catch {add_wave -into L15_Encoder -radix bin   ${T0}/l15/l15/noc1buffer_noc1encoder_req_val}

# =============================================================================
catch {set_property needs_save false [get_wave_configs]}
catch {wave zoom full}

puts "INFO: wave.tcl carregado — chip.v integrado, [llength [get_waves -quiet]] sinais adicionados"
