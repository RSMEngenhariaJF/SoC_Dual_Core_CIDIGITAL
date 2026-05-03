# ============================================================
# Vivado Simulator (xsim) — configuração do Dual-Core CVA6
# Testbench: tb_dual_core_cva6.v
#
# Author: Elivander Judas Tadeu Pereira - Inatel
# Date: 2026-03-20  |  Atualizado: 2026-04-26
# Version: 2.1
# ============================================================


# ===================== Controle do script ===================
set SCRIPT_TARGET   "all"
set GUI_MODE        "gui"

# Sem UVM neste projeto
set UVM_TEST        ""
set UVM_VERBOSITY   ""
set UVM_ARGS        [list]
set RND_SEED        1


# ================== Diretórios base =========================
set ROOT_DIR  [file normalize [file dirname [info script]]]
set RUN_DIR   "$ROOT_DIR/work/sim"

# Diretório do design fonte (repositório OpenPiton)
set PITON_DIR [file normalize "$ROOT_DIR/../.."]
set DESIGN    "$PITON_DIR/piton/design"
set ARIANE    "$DESIGN/chip/tile/ariane"

# Diretórios de RTL gerado e testbench
set RTL_PATHS "$ROOT_DIR/rtl"
set TB_PATHS  "$ROOT_DIR/tb"
set INC_DIR   "$ROOT_DIR/include"


# ================== Defines de compilação ===================
set XVLOG_DEFINES [list \
    "--define" "PITON_ARIANE"           \
    "--define" "PITON_CHIP_FPGA"        \
    "--define" "PITON_FPGA_SYNTH"       \
    "--define" "WT_DCACHE"              \
    "--define" "PITON_RV64_PLATFORM"    \
    "--define" "PITON_RV64_PLIC"        \
    "--define" "PITON_RV64_CLINT"       \
    "--define" "PITON_RV64_DEBUGUNIT"   \
    "--define" "XSIM"                   \
    "--define" "PITON_NO_CHIP_BRIDGE"   \
    "--define" "VC707_BOARD"            \
]


# ================== Include dirs extras =====================
set XVLOG_INC_DIRS [list \
    "--include" "$INC_DIR"                                                              \
    "--include" "$DESIGN/include"                                                       \
    "--include" "$ARIANE/common/local/util"                                             \
    "--include" "$ARIANE/common/submodules/common_cells/include"                        \
    "--include" "$ARIANE/corev_apu/register_interface/include"                         \
    "--include" "$PITON_DIR/piton/design/chipset/include"                              \
    "--include" "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl"                 \
]


# ================== TOP do testbench ========================
# tb_soc_dual_core : chip.v como DUT + noc_axi4_bridge + AXI4 SRAM (UVM-ready)
# tb_dual_core_cva6: testbench original (tiles diretos, sem memória)
set TOP_NAME "tb_soc_dual_core"


# ================== Arquivos RTL (DUT) ======================
# NOTA: usa lappend para evitar o problema de linhas em branco
# dentro de [list \...] em Tcl (newline = separador de comandos).
set XVHDL_RTL_FILES [list]
set XVLOG_RTL_FILES {}

# --- 1. Packages CVA6 (compilar ANTES dos módulos) ---
lappend XVLOG_RTL_FILES \
    "$ARIANE/core/include/cv64a6_imafdc_sv39_openpiton_config_pkg.sv" \
    "$ARIANE/core/include/riscv_pkg.sv"                               \
    "$ARIANE/corev_apu/riscv-dbg/src/dm_pkg.sv"                      \
    "$ARIANE/core/include/ariane_pkg.sv"                              \
    "$ARIANE/corev_apu/tb/ariane_soc_pkg.sv"                         \
    "$ARIANE/corev_apu/axi/src/axi_pkg.sv"                           \
    "$ARIANE/core/include/ariane_axi_pkg.sv"                         \
    "$ARIANE/core/include/wt_cache_pkg.sv"                           \
    "$ARIANE/core/include/axi_intf.sv"                               \
    "$ARIANE/core/fpu/src/fpnew_pkg.sv"                              \
    "$ARIANE/core/include/cvxif_pkg.sv"                              \
    "$ARIANE/common/submodules/common_cells/src/cf_math_pkg.sv"      \
    "$ARIANE/core/include/instr_tracer_pkg.sv"                       \
    "$ARIANE/core/cvxif_example/include/cvxif_instr_pkg.sv"         \
    "$ARIANE/corev_apu/rv_plic/rtl/rv_plic_reg_pkg.sv"

# --- 2. Células comuns (common_cells, tech_cells) ---
lappend XVLOG_RTL_FILES \
    "$ARIANE/common/local/util/sram.sv"                                             \
    "$ARIANE/common/submodules/common_cells/src/deprecated/rrarbiter.sv"            \
    "$ARIANE/common/submodules/common_cells/src/deprecated/fifo_v1.sv"              \
    "$ARIANE/common/submodules/common_cells/src/deprecated/fifo_v2.sv"              \
    "$ARIANE/common/submodules/common_cells/src/fifo_v3.sv"                         \
    "$ARIANE/common/submodules/common_cells/src/shift_reg.sv"                       \
    "$ARIANE/common/submodules/common_cells/src/lfsr_8bit.sv"                       \
    "$ARIANE/common/submodules/common_cells/src/lfsr.sv"                            \
    "$ARIANE/common/submodules/common_cells/src/lzc.sv"                             \
    "$ARIANE/common/submodules/common_cells/src/exp_backoff.sv"                     \
    "$ARIANE/common/submodules/common_cells/src/rr_arb_tree.sv"                     \
    "$ARIANE/common/submodules/common_cells/src/rstgen_bypass.sv"                   \
    "$ARIANE/common/submodules/common_cells/src/cdc_2phase.sv"                      \
    "$ARIANE/common/submodules/common_cells/src/unread.sv"                          \
    "$ARIANE/common/submodules/common_cells/src/popcount.sv"                        \
    "$ARIANE/common/submodules/common_cells/src/counter.sv"                         \
    "$ARIANE/common/submodules/common_cells/src/delta_counter.sv"                   \
    "$ARIANE/corev_apu/axi_mem_if/src/axi2mem.sv"                                   \
    "$ARIANE/corev_apu/src/tech_cells_generic/src/deprecated/cluster_clk_cells.sv" \
    "$ARIANE/corev_apu/src/tech_cells_generic/src/deprecated/pulp_clk_cells.sv"    \
    "$ARIANE/common/local/util/tc_sram_wrapper.sv"                                  \
    "$ARIANE/corev_apu/src/tech_cells_generic/src/rtl/tc_sram.sv"                  \
    "$ARIANE/corev_apu/src/tech_cells_generic/src/rtl/tc_clk.sv"

# --- 3a. Core CVA6 — pipeline ---
lappend XVLOG_RTL_FILES \
    "$ARIANE/core/axi_adapter.sv"           \
    "$ARIANE/core/alu.sv"                   \
    "$ARIANE/core/fpu_wrap.sv"              \
    "$ARIANE/core/ariane.sv"                \
    "$ARIANE/core/cva6.sv"                  \
    "$ARIANE/core/branch_unit.sv"           \
    "$ARIANE/core/compressed_decoder.sv"    \
    "$ARIANE/core/controller.sv"            \
    "$ARIANE/core/csr_buffer.sv"            \
    "$ARIANE/core/csr_regfile.sv"           \
    "$ARIANE/core/decoder.sv"               \
    "$ARIANE/core/ex_stage.sv"              \
    "$ARIANE/core/frontend/btb.sv"          \
    "$ARIANE/core/frontend/bht.sv"          \
    "$ARIANE/core/frontend/ras.sv"          \
    "$ARIANE/core/frontend/instr_scan.sv"   \
    "$ARIANE/core/frontend/instr_queue.sv"  \
    "$ARIANE/core/frontend/frontend.sv"     \
    "$ARIANE/core/id_stage.sv"              \
    "$ARIANE/core/instr_realign.sv"         \
    "$ARIANE/core/issue_read_operands.sv"   \
    "$ARIANE/core/issue_stage.sv"           \
    "$ARIANE/core/load_unit.sv"             \
    "$ARIANE/core/load_store_unit.sv"       \
    "$ARIANE/core/lsu_bypass.sv"            \
    "$ARIANE/core/mmu_sv39/mmu.sv"          \
    "$ARIANE/core/mult.sv"                  \
    "$ARIANE/core/multiplier.sv"            \
    "$ARIANE/core/serdiv.sv"                \
    "$ARIANE/core/perf_counters.sv"         \
    "$ARIANE/core/mmu_sv39/ptw.sv"          \
    "$ARIANE/core/ariane_regfile_ff.sv"     \
    "$ARIANE/core/re_name.sv"               \
    "$ARIANE/core/scoreboard.sv"            \
    "$ARIANE/core/store_buffer.sv"          \
    "$ARIANE/core/amo_buffer.sv"            \
    "$ARIANE/core/store_unit.sv"            \
    "$ARIANE/core/mmu_sv39/tlb.sv"          \
    "$ARIANE/core/commit_stage.sv"

# --- 3b. Cache subsystem (write-through para P-Mesh) ---
lappend XVLOG_RTL_FILES \
    "$ARIANE/core/cache_subsystem/wt_dcache_ctrl.sv"          \
    "$ARIANE/core/cache_subsystem/wt_dcache_mem.sv"           \
    "$ARIANE/core/cache_subsystem/wt_dcache_missunit.sv"      \
    "$ARIANE/core/cache_subsystem/wt_dcache_wbuffer.sv"       \
    "$ARIANE/core/cache_subsystem/wt_dcache.sv"               \
    "$ARIANE/core/cache_subsystem/cva6_icache.sv"             \
    "$ARIANE/core/cache_subsystem/cva6_icache_axi_wrapper.sv" \
    "$ARIANE/core/cache_subsystem/wt_l15_adapter.sv"          \
    "$ARIANE/core/cache_subsystem/wt_cache_subsystem.sv"

# --- 3c. FPU (fpnew — RV64FD) ---
lappend XVLOG_RTL_FILES \
    "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv"    \
    "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv"          \
    "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_mvp_wrapper.sv" \
    "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv"     \
    "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv" \
    "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv"    \
    "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv"        \
    "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv"       \
    "$ARIANE/core/fpu/src/fpnew_cast_multi.sv"             \
    "$ARIANE/core/fpu/src/fpnew_classifier.sv"             \
    "$ARIANE/core/fpu/src/fpnew_divsqrt_multi.sv"          \
    "$ARIANE/core/fpu/src/fpnew_fma_multi.sv"              \
    "$ARIANE/core/fpu/src/fpnew_fma.sv"                    \
    "$ARIANE/core/fpu/src/fpnew_noncomp.sv"                \
    "$ARIANE/core/fpu/src/fpnew_opgroup_block.sv"          \
    "$ARIANE/core/fpu/src/fpnew_opgroup_fmt_slice.sv"      \
    "$ARIANE/core/fpu/src/fpnew_opgroup_multifmt_slice.sv" \
    "$ARIANE/core/fpu/src/fpnew_rounding.sv"               \
    "$ARIANE/core/fpu/src/fpnew_top.sv"

# --- 3d. PMP, CvxIF, tracer ---
lappend XVLOG_RTL_FILES \
    "$ARIANE/core/pmp/src/pmp_entry.sv"                       \
    "$ARIANE/core/pmp/src/pmp.sv"                             \
    "$ARIANE/core/cvxif_example/cvxif_example_coprocessor.sv" \
    "$ARIANE/core/cvxif_example/instr_decoder.sv"             \
    "$ARIANE/core/cvxif_fu.sv"                                \
    "$ARIANE/common/local/util/instr_tracer_if.sv"            \
    "$ARIANE/common/local/util/instr_tracer.sv"

# --- 3e. Periféricos OpenPiton + wrapper Ariane ---
lappend XVLOG_RTL_FILES \
    "$ARIANE/corev_apu/clint/axi_lite_interface.sv"              \
    "$ARIANE/corev_apu/clint/clint.sv"                           \
    "$ARIANE/corev_apu/riscv-dbg/debug_rom/debug_rom.sv"         \
    "$ARIANE/corev_apu/riscv-dbg/src/dm_csrs.sv"                 \
    "$ARIANE/corev_apu/riscv-dbg/src/dm_mem.sv"                  \
    "$ARIANE/corev_apu/riscv-dbg/src/dm_top.sv"                  \
    "$ARIANE/corev_apu/riscv-dbg/src/dmi_cdc.sv"                 \
    "$ARIANE/corev_apu/riscv-dbg/src/dmi_jtag.sv"                \
    "$ARIANE/corev_apu/riscv-dbg/src/dm_sba.sv"                  \
    "$ARIANE/corev_apu/riscv-dbg/src/dmi_jtag_tap.sv"            \
    "$ARIANE/corev_apu/openpiton/riscv_peripherals.sv"            \
    "$ARIANE/corev_apu/openpiton/ariane_verilog_wrap.sv"          \
    "$ARIANE/corev_apu/rv_plic/rtl/rv_plic_target.sv"            \
    "$ARIANE/corev_apu/rv_plic/rtl/rv_plic_gateway.sv"           \
    "$ARIANE/corev_apu/rv_plic/rtl/plic_regmap.sv"               \
    "$ARIANE/corev_apu/rv_plic/rtl/plic_top.sv"                  \
    "$ARIANE/corev_apu/fpga/src/axi2apb/src/axi2apb_wrap.sv"     \
    "$ARIANE/corev_apu/fpga/src/axi2apb/src/axi2apb.sv"          \
    "$ARIANE/corev_apu/fpga/src/axi2apb/src/axi2apb_64_32.sv"    \
    "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_w_buffer.sv"   \
    "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_b_buffer.sv"   \
    "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_slice_wrap.sv" \
    "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_slice.sv"      \
    "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_single_slice.sv" \
    "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_ar_buffer.sv"  \
    "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_r_buffer.sv"   \
    "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_aw_buffer.sv"  \
    "$ARIANE/corev_apu/register_interface/src/apb_to_reg.sv"     \
    "$ARIANE/corev_apu/register_interface/src/reg_intf.sv"

# --- 4. Infraestrutura OpenPiton (Verilog estático) ---
lappend XVLOG_RTL_FILES \
    "$DESIGN/chip/tile/common/rtl/swrvr_clib.v"        \
    "$DESIGN/chip/tile/common/rtl/clk_gating_latch.v"  \
    "$DESIGN/chip/tile/common/rtl/credit_to_valrdy.v"  \
    "$DESIGN/chip/tile/common/rtl/valrdy_to_credit.v"  \
    "$DESIGN/chip/tile/common/rtl/ucb_bus_in.v"        \
    "$DESIGN/chip/tile/common/rtl/ucb_bus_out.v"       \
    "$DESIGN/chip/tile/common/rtl/ucb_flow_2buf.v"     \
    "$DESIGN/chip/tile/common/rtl/ucb_noflow.v"        \
    "$DESIGN/chip/tile/common/rtl/dbl_buf.v"           \
    "$DESIGN/chip/tile/rtl/ccx_l15_transducer.v"       \
    "$DESIGN/common/rtl/synchronizer.v"                \
    "$DESIGN/common/rtl/async_fifo.v"                  \
    "$DESIGN/common/rtl/sync_fifo_vr.v"                \
    "$DESIGN/common/rtl/noc_simple_merger.v"           \
    "$DESIGN/common/rtl/noc_simple_splitter.v"         \
    "$DESIGN/common/rtl/bram_1rw_wrapper.v"            \
    "$DESIGN/common/rtl/bram_1r1w_wrapper.v"

# --- 5. RTL gerado — tile top + utilitários ---
lappend XVLOG_RTL_FILES \
    "$RTL_PATHS/chip/tile/rtl/tile.v"                 \
    "$RTL_PATHS/chip/tile/rtl/config_regs.v"          \
    "$RTL_PATHS/chip/tile/common/rtl/flat_id_to_xy.v" \
    "$RTL_PATHS/chip/tile/common/rtl/xy_to_flat_id.v" \
    "$RTL_PATHS/chip/tile/dmbr/rtl/dmbr.v"

# --- 5b. Dynamic NoC router (cadeia estática — usada pelo tile.v gerado) ---
lappend XVLOG_RTL_FILES \
    "$DESIGN/chip/tile/dynamic_node/components/rtl/bus_compare_equal.v"       \
    "$DESIGN/chip/tile/dynamic_node/components/rtl/flip_bus.v"                \
    "$DESIGN/chip/tile/dynamic_node/components/rtl/net_dff.v"                 \
    "$DESIGN/chip/tile/dynamic_node/components/rtl/one_of_five.v"             \
    "$DESIGN/chip/tile/dynamic_node/components/rtl/one_of_eight.v"            \
    "$DESIGN/chip/tile/dynamic_node/common/rtl/network_input_blk_multi_out.v" \
    "$DESIGN/chip/tile/dynamic_node/common/rtl/space_avail_top.v"             \
    "$DESIGN/chip/tile/dynamic_node/dynamic/rtl/dynamic_input_control.v"      \
    "$DESIGN/chip/tile/dynamic_node/dynamic/rtl/dynamic_input_route_request_calc.v" \
    "$DESIGN/chip/tile/dynamic_node/dynamic/rtl/dynamic_input_top_4.v"        \
    "$DESIGN/chip/tile/dynamic_node/dynamic/rtl/dynamic_input_top_16.v"       \
    "$DESIGN/chip/tile/dynamic_node/dynamic/rtl/dynamic_output_control.v"     \
    "$DESIGN/chip/tile/dynamic_node/dynamic/rtl/dynamic_output_datapath.v"    \
    "$DESIGN/chip/tile/dynamic_node/dynamic/rtl/dynamic_output_top.v"         \
    "$DESIGN/chip/tile/dynamic_node/rtl/dynamic_node_top.v"                   \
    "$DESIGN/chip/tile/dynamic_node/rtl/dynamic_node_top_wrap.v"

# --- 5c. L1.5 cache (P-Mesh) ---
lappend XVLOG_RTL_FILES \
    "$RTL_PATHS/chip/tile/l15/rtl/l15_csm.v"                     \
    "$RTL_PATHS/chip/tile/l15/rtl/l15_hmc.v"                     \
    "$RTL_PATHS/chip/tile/l15/rtl/l15_home_encoder.v"            \
    "$RTL_PATHS/chip/tile/l15/rtl/l15_mshr.v"                    \
    "$RTL_PATHS/chip/tile/l15/rtl/l15_pipeline.v"                \
    "$RTL_PATHS/chip/tile/l15/rtl/l15_priority_encoder.v"        \
    "$RTL_PATHS/chip/tile/l15/rtl/noc1buffer.v"                  \
    "$RTL_PATHS/chip/tile/l15/rtl/rf_l15_lrsc_flag.v"            \
    "$RTL_PATHS/chip/tile/l15/rtl/rf_l15_lruarray.v"             \
    "$RTL_PATHS/chip/tile/l15/rtl/rf_l15_mesi.v"                 \
    "$RTL_PATHS/chip/tile/l15/rtl/rf_l15_wmt.v"                  \
    "$RTL_PATHS/chip/tile/l15/rtl/sram_wrappers/sram_l15_data.v" \
    "$RTL_PATHS/chip/tile/l15/rtl/sram_wrappers/sram_l15_hmt.v"  \
    "$RTL_PATHS/chip/tile/l15/rtl/sram_wrappers/sram_l15_tag.v"

# --- 5d. L2 cache (gerado — folhas parametrizadas) ---
lappend XVLOG_RTL_FILES \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_data_ecc.v"                 \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_data_pgen.v"                \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_mshr.v"                     \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_mshr_wrap.v"                \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_pipe1_buf_in.v"             \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_pipe1_buf_out.v"            \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_pipe1_ctrl.v"               \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_pipe1_dpath.v"              \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_pipe2_buf_in.v"             \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_pipe2_ctrl.v"               \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_pipe2_dpath.v"              \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_priority_encoder.v"         \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_smc.v"                      \
    "$RTL_PATHS/chip/tile/l2/rtl/l2_state.v"                    \
    "$RTL_PATHS/chip/tile/l2/rtl/sram_wrappers/sram_l2_data.v"  \
    "$RTL_PATHS/chip/tile/l2/rtl/sram_wrappers/sram_l2_dir.v"   \
    "$RTL_PATHS/chip/tile/l2/rtl/sram_wrappers/sram_l2_state.v" \
    "$RTL_PATHS/chip/tile/l2/rtl/sram_wrappers/sram_l2_tag.v"

# --- 5d2. L15 — sub-módulos estáticos ---
lappend XVLOG_RTL_FILES \
    "$DESIGN/chip/tile/l15/rtl/simplenocbuffer.v"   \
    "$DESIGN/chip/tile/l15/rtl/noc2decoder.v"        \
    "$DESIGN/chip/tile/l15/rtl/pcx_buffer.v"         \
    "$DESIGN/chip/tile/l15/rtl/pcx_decoder.v"        \
    "$DESIGN/chip/tile/l15/rtl/pico_decoder.v"       \
    "$DESIGN/chip/tile/l15/rtl/l15_picoencoder.v"    \
    "$DESIGN/chip/tile/l15/rtl/l15_cpxencoder.v"     \
    "$DESIGN/chip/tile/l15/rtl/noc1encoder.v"        \
    "$DESIGN/chip/tile/l15/rtl/noc3buffer.v"         \
    "$DESIGN/chip/tile/l15/rtl/noc3encoder.v"        \
    "$DESIGN/chip/tile/l15/rtl/l15.v"                \
    "$DESIGN/chip/tile/l15/rtl/l15_wrap.v"

# --- 5d3. L2 — wrappers estáticos ---
lappend XVLOG_RTL_FILES \
    "$DESIGN/chip/tile/l2/rtl/l2_amo_alu.v"               \
    "$DESIGN/chip/tile/l2/rtl/l2_broadcast_counter.v"      \
    "$DESIGN/chip/tile/l2/rtl/l2_broadcast_counter_wrap.v" \
    "$DESIGN/chip/tile/l2/rtl/l2_config_regs.v"            \
    "$DESIGN/chip/tile/l2/rtl/l2_decoder.v"                \
    "$DESIGN/chip/tile/l2/rtl/l2_encoder.v"                \
    "$DESIGN/chip/tile/l2/rtl/l2_mshr_decoder.v"           \
    "$DESIGN/chip/tile/l2/rtl/l2_debug.v"                  \
    "$DESIGN/chip/tile/l2/rtl/l2_data.v"                   \
    "$DESIGN/chip/tile/l2/rtl/l2_data_wrap.v"              \
    "$DESIGN/chip/tile/l2/rtl/l2_dir.v"                    \
    "$DESIGN/chip/tile/l2/rtl/l2_dir_wrap.v"               \
    "$DESIGN/chip/tile/l2/rtl/l2_tag.v"                    \
    "$DESIGN/chip/tile/l2/rtl/l2_tag_wrap.v"               \
    "$DESIGN/chip/tile/l2/rtl/l2_state_wrap.v"             \
    "$DESIGN/chip/tile/l2/rtl/l2_smc_wrap.v"               \
    "$DESIGN/chip/tile/l2/rtl/l2_pipe1.v"                  \
    "$DESIGN/chip/tile/l2/rtl/l2_pipe2.v"                  \
    "$DESIGN/chip/tile/l2/rtl/l2.v"

# --- 5d4. RTAP ---
lappend XVLOG_RTL_FILES \
    "$DESIGN/chip/tile/rtap/rtl/rtap_ucb_receiver.v"    \
    "$DESIGN/chip/tile/rtap/rtl/rtap_ucb_transmitter.v" \
    "$DESIGN/chip/tile/rtap/rtl/rtap.v"

# --- 5e. Common gerado ---
lappend XVLOG_RTL_FILES \
    "$RTL_PATHS/common/rtl/noc_fbits_splitter.v" \
    "$RTL_PATHS/common/rtl/noc_prio_merger.v"    \
    "$RTL_PATHS/common/rtl/bram_sdp_wrapper.v"

# --- 6. chip.v top-level + módulos de suporte ---
lappend XVLOG_RTL_FILES \
    "$PITON_DIR/piton/design/chip/rtl/OCI.v"              \
    "$PITON_DIR/piton/design/chip/pll/rtl/clk_se_to_diff.v" \
    "$PITON_DIR/piton/design/chip/pll/rtl/clk_mux.v"     \
    "$PITON_DIR/piton/design/chip/jtag/rtl/jtag_ucb_receiver.v"   \
    "$PITON_DIR/piton/design/chip/jtag/rtl/jtag_ucb_transmitter.v" \
    "$PITON_DIR/piton/design/chip/jtag/rtl/jtag_interface_tap.v"  \
    "$PITON_DIR/piton/design/chip/jtag/rtl/jtag_interface.v"      \
    "$PITON_DIR/piton/design/chip/jtag/rtl/jtag_ctap.v"           \
    "$PITON_DIR/piton/design/chip/jtag/rtl/jtag.v"                \
    "$RTL_PATHS/chip/rtl/chip.v"

# --- 7. noc_axi4_bridge (NoC → AXI4) ---
lappend XVLOG_RTL_FILES \
    "$RTL_PATHS/chipset/rtl/storage_addr_trans.v"                        \
    "$RTL_PATHS/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_sram_data.v" \
    "$RTL_PATHS/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_sram_req.v"  \
    "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl/axi4_zeroer.v"          \
    "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_deser.v" \
    "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_ser.v"   \
    "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_read.v"  \
    "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_write.v" \
    "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_buffer.v" \
    "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge.v"


# ================== Arquivos do Testbench ===================
set XVHDL_TB_FILES [list]

set XVLOG_TB_FILES [list \
    "$TB_PATHS/stubs.v"               \
    "$TB_PATHS/protocol_adapter.v"    \
    "$TB_PATHS/axi4_sram_model.v"     \
    "$TB_PATHS/tb_soc_dual_core.v"    \
]
