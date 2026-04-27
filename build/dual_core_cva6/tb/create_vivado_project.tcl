# =============================================================================
# create_vivado_project.tcl
# Cria projeto Vivado para simulação do testbench Dual-Core CVA6 (OpenPiton)
#
# Como usar — Vivado Tcl Console:
#   cd C:/Users/rafae/Documents/SoC_dual_core/openpiton/build/dual_core_cva6/tb
#   source create_vivado_project.tcl
#
# Como usar — linha de comando:
#   vivado -mode batch -source create_vivado_project.tcl
# =============================================================================

# --- Caminhos base -----------------------------------------------------------
set TB_DIR    [file normalize [file dirname [info script]]]
set BUILD_DIR [file normalize "$TB_DIR/.."]
set PITON_DIR [file normalize "$BUILD_DIR/../.."]
set DESIGN    "$PITON_DIR/piton/design"
set ARIANE    "$DESIGN/chip/tile/ariane"

# --- Cria o projeto ----------------------------------------------------------
set PROJ_NAME "dual_core_cva6_sim"
set PROJ_DIR  "$TB_DIR/vivado_proj"

create_project $PROJ_NAME $PROJ_DIR -part xc7a200tsbg484-1 -force
set_property simulator_language Mixed [current_project]
set_property target_simulator XSim   [current_project]

# =============================================================================
# DEFINES globais de simulação
# =============================================================================
set SIM_DEFINES {
    PITON_ARIANE
    PITON_CHIP_FPGA
    PITON_FPGA_SYNTH
    WT_DCACHE
}

# =============================================================================
# INCLUDE DIRS
# =============================================================================
set INC_DIRS [list \
    "$BUILD_DIR/include"                                          \
    "$DESIGN/include"                                             \
    "$ARIANE/common/local/util"                                   \
    "$ARIANE/common/submodules/common_cells/include"             \
    "$ARIANE/corev_apu/register_interface/include"               \
]

# =============================================================================
# Função auxiliar: adiciona arquivo Verilog/SystemVerilog ao projeto
# =============================================================================
proc add_sv { filepath {lib work} } {
    if {[file exists $filepath]} {
        add_files -norecurse $filepath
        set_property file_type SystemVerilog [get_files $filepath]
        set_property library $lib [get_files $filepath]
    } else {
        puts "AVISO: arquivo não encontrado — $filepath"
    }
}

proc add_v { filepath {lib work} } {
    if {[file exists $filepath]} {
        add_files -norecurse $filepath
        set_property file_type Verilog [get_files $filepath]
        set_property library $lib [get_files $filepath]
    } else {
        puts "AVISO: arquivo não encontrado — $filepath"
    }
}

# =============================================================================
# 1. PACKAGES CVA6 — devem ser compilados PRIMEIRO
# =============================================================================
add_sv "$ARIANE/core/include/cv64a6_imafdc_sv39_openpiton_config_pkg.sv"
add_sv "$ARIANE/core/include/riscv_pkg.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/src/dm_pkg.sv"
add_sv "$ARIANE/core/include/ariane_pkg.sv"
add_sv "$ARIANE/corev_apu/tb/ariane_soc_pkg.sv"
add_sv "$ARIANE/corev_apu/axi/src/axi_pkg.sv"
add_sv "$ARIANE/core/include/ariane_axi_pkg.sv"
add_sv "$ARIANE/core/include/wt_cache_pkg.sv"
add_sv "$ARIANE/core/include/axi_intf.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_pkg.sv"
add_sv "$ARIANE/core/include/cvxif_pkg.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/cf_math_pkg.sv"
add_sv "$ARIANE/core/include/instr_tracer_pkg.sv"
add_sv "$ARIANE/core/cvxif_example/include/cvxif_instr_pkg.sv"
add_sv "$ARIANE/corev_apu/rv_plic/rtl/rv_plic_reg_pkg.sv"

# =============================================================================
# 2. CÉLULAS COMUNS (common_cells, tech_cells)
# =============================================================================
add_sv "$ARIANE/common/local/util/sram.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/deprecated/rrarbiter.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/deprecated/fifo_v1.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/deprecated/fifo_v2.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/fifo_v3.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/shift_reg.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/lfsr_8bit.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/lfsr.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/lzc.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/exp_backoff.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/rr_arb_tree.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/rstgen_bypass.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/cdc_2phase.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/unread.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/popcount.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/counter.sv"
add_sv "$ARIANE/common/submodules/common_cells/src/delta_counter.sv"
add_sv "$ARIANE/corev_apu/axi_mem_if/src/axi2mem.sv"
add_sv "$ARIANE/corev_apu/src/tech_cells_generic/src/deprecated/cluster_clk_cells.sv"
add_sv "$ARIANE/corev_apu/src/tech_cells_generic/src/deprecated/pulp_clk_cells.sv"
add_sv "$ARIANE/common/local/util/tc_sram_wrapper.sv"
add_sv "$ARIANE/corev_apu/src/tech_cells_generic/src/rtl/tc_sram.sv"
add_sv "$ARIANE/corev_apu/src/tech_cells_generic/src/rtl/tc_clk.sv"

# =============================================================================
# 3. CORE CVA6 (pipeline, cache, FPU, MMU)
# =============================================================================
add_sv "$ARIANE/core/axi_adapter.sv"
add_sv "$ARIANE/core/alu.sv"
add_sv "$ARIANE/core/fpu_wrap.sv"
add_sv "$ARIANE/core/ariane.sv"
add_sv "$ARIANE/core/cva6.sv"
add_sv "$ARIANE/core/branch_unit.sv"
add_sv "$ARIANE/core/compressed_decoder.sv"
add_sv "$ARIANE/core/controller.sv"
add_sv "$ARIANE/core/csr_buffer.sv"
add_sv "$ARIANE/core/csr_regfile.sv"
add_sv "$ARIANE/core/decoder.sv"
add_sv "$ARIANE/core/ex_stage.sv"
add_sv "$ARIANE/core/frontend/btb.sv"
add_sv "$ARIANE/core/frontend/bht.sv"
add_sv "$ARIANE/core/frontend/ras.sv"
add_sv "$ARIANE/core/frontend/instr_scan.sv"
add_sv "$ARIANE/core/frontend/instr_queue.sv"
add_sv "$ARIANE/core/frontend/frontend.sv"
add_sv "$ARIANE/core/id_stage.sv"
add_sv "$ARIANE/core/instr_realign.sv"
add_sv "$ARIANE/core/issue_read_operands.sv"
add_sv "$ARIANE/core/issue_stage.sv"
add_sv "$ARIANE/core/load_unit.sv"
add_sv "$ARIANE/core/load_store_unit.sv"
add_sv "$ARIANE/core/lsu_bypass.sv"
add_sv "$ARIANE/core/mmu_sv39/mmu.sv"
add_sv "$ARIANE/core/mult.sv"
add_sv "$ARIANE/core/multiplier.sv"
add_sv "$ARIANE/core/serdiv.sv"
add_sv "$ARIANE/core/perf_counters.sv"
add_sv "$ARIANE/core/mmu_sv39/ptw.sv"
add_sv "$ARIANE/core/ariane_regfile_ff.sv"
add_sv "$ARIANE/core/re_name.sv"
add_sv "$ARIANE/core/scoreboard.sv"
add_sv "$ARIANE/core/store_buffer.sv"
add_sv "$ARIANE/core/amo_buffer.sv"
add_sv "$ARIANE/core/store_unit.sv"
add_sv "$ARIANE/core/mmu_sv39/tlb.sv"
add_sv "$ARIANE/core/commit_stage.sv"

# Cache subsystem
add_sv "$ARIANE/core/cache_subsystem/wt_dcache_ctrl.sv"
add_sv "$ARIANE/core/cache_subsystem/wt_dcache_mem.sv"
add_sv "$ARIANE/core/cache_subsystem/wt_dcache_missunit.sv"
add_sv "$ARIANE/core/cache_subsystem/wt_dcache_wbuffer.sv"
add_sv "$ARIANE/core/cache_subsystem/wt_dcache.sv"
add_sv "$ARIANE/core/cache_subsystem/cva6_icache.sv"
add_sv "$ARIANE/core/cache_subsystem/cva6_icache_axi_wrapper.sv"
add_sv "$ARIANE/core/cache_subsystem/wt_l15_adapter.sv"
add_sv "$ARIANE/core/cache_subsystem/wt_cache_subsystem.sv"

# FPU
add_sv "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv"
add_sv "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv"
add_sv "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_mvp_wrapper.sv"
add_sv "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv"
add_sv "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv"
add_sv "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv"
add_sv "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv"
add_sv "$ARIANE/core/fpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_cast_multi.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_classifier.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_divsqrt_multi.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_fma_multi.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_fma.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_noncomp.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_opgroup_block.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_opgroup_fmt_slice.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_opgroup_multifmt_slice.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_rounding.sv"
add_sv "$ARIANE/core/fpu/src/fpnew_top.sv"

# PMP, CvxIF, periféricos OpenPiton
add_sv "$ARIANE/core/pmp/src/pmp.sv"
add_sv "$ARIANE/core/pmp/src/pmp_entry.sv"
add_sv "$ARIANE/core/cvxif_example/cvxif_example_coprocessor.sv"
add_sv "$ARIANE/core/cvxif_example/instr_decoder.sv"
add_sv "$ARIANE/core/cvxif_fu.sv"
add_sv "$ARIANE/common/local/util/instr_tracer_if.sv"
add_sv "$ARIANE/common/local/util/instr_tracer.sv"

# Periféricos OpenPiton + wrapper
add_sv "$ARIANE/corev_apu/clint/axi_lite_interface.sv"
add_sv "$ARIANE/corev_apu/clint/clint.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/debug_rom/debug_rom.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/src/dm_csrs.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/src/dm_mem.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/src/dm_top.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/src/dmi_cdc.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/src/dmi_jtag.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/src/dm_sba.sv"
add_sv "$ARIANE/corev_apu/riscv-dbg/src/dmi_jtag_tap.sv"
add_sv "$ARIANE/corev_apu/openpiton/riscv_peripherals.sv"
add_sv "$ARIANE/corev_apu/openpiton/ariane_verilog_wrap.sv"
add_sv "$ARIANE/corev_apu/rv_plic/rtl/rv_plic_target.sv"
add_sv "$ARIANE/corev_apu/rv_plic/rtl/rv_plic_gateway.sv"
add_sv "$ARIANE/corev_apu/rv_plic/rtl/plic_regmap.sv"
add_sv "$ARIANE/corev_apu/rv_plic/rtl/plic_top.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi2apb/src/axi2apb_wrap.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi2apb/src/axi2apb.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi2apb/src/axi2apb_64_32.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_w_buffer.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_b_buffer.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_slice_wrap.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_slice.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_single_slice.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_ar_buffer.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_r_buffer.sv"
add_sv "$ARIANE/corev_apu/fpga/src/axi_slice/src/axi_aw_buffer.sv"
add_sv "$ARIANE/corev_apu/register_interface/src/apb_to_reg.sv"
add_sv "$ARIANE/corev_apu/register_interface/src/reg_intf.sv"

# =============================================================================
# 4. INFRAESTRUTURA OPENPITON (Verilog estático)
# =============================================================================
# Células comuns do tile
add_v "$DESIGN/chip/tile/common/rtl/clk_gating_latch.v"
add_v "$DESIGN/chip/tile/common/rtl/synchronizer.v"
add_v "$DESIGN/chip/tile/common/rtl/credit_to_valrdy.v"
add_v "$DESIGN/chip/tile/common/rtl/valrdy_to_credit.v"
add_v "$DESIGN/chip/tile/common/rtl/ucb_bus_in.v"
add_v "$DESIGN/chip/tile/common/rtl/ucb_bus_out.v"
add_v "$DESIGN/chip/tile/common/rtl/ucb_flow_2buf.v"
add_v "$DESIGN/chip/tile/common/rtl/ucb_noflow.v"
add_v "$DESIGN/chip/tile/common/rtl/dbl_buf.v"

# Transdutor L15 ↔ CVA6
add_v "$DESIGN/chip/tile/rtl/ccx_l15_transducer.v"

# Common design
add_v "$DESIGN/common/rtl/synchronizer.v"
add_v "$DESIGN/common/rtl/async_fifo.v"
add_v "$DESIGN/common/rtl/sync_fifo_vr.v"
add_v "$DESIGN/common/rtl/noc_simple_merger.v"
add_v "$DESIGN/common/rtl/noc_simple_splitter.v"
add_v "$DESIGN/common/rtl/bram_1rw_wrapper.v"
add_v "$DESIGN/common/rtl/bram_1r1w_wrapper.v"

# =============================================================================
# 5. RTL GERADO (chip/tile/l15/l2/NoC)
# =============================================================================
# Tile top
add_v "$BUILD_DIR/rtl/chip/tile/rtl/tile.v"
add_v "$BUILD_DIR/rtl/chip/tile/rtl/config_regs.v"
add_v "$BUILD_DIR/rtl/chip/tile/common/rtl/flat_id_to_xy.v"
add_v "$BUILD_DIR/rtl/chip/tile/common/rtl/xy_to_flat_id.v"
add_v "$BUILD_DIR/rtl/chip/tile/dmbr/rtl/dmbr.v"

# Dynamic NoC router
foreach f [glob "$BUILD_DIR/rtl/chip/tile/dynamic_node/components/rtl/*.v"] { add_v $f }
foreach f [glob "$BUILD_DIR/rtl/chip/tile/dynamic_node/dynamic/rtl/*.v"]    { add_v $f }
foreach f [glob "$BUILD_DIR/rtl/chip/tile/dynamic_node/rtl/*.v"]            { add_v $f }

# L1.5 cache
foreach f [glob "$BUILD_DIR/rtl/chip/tile/l15/rtl/*.v"]              { add_v $f }
foreach f [glob "$BUILD_DIR/rtl/chip/tile/l15/rtl/sram_wrappers/*.v"] { add_v $f }

# L2 cache
foreach f [glob "$BUILD_DIR/rtl/chip/tile/l2/rtl/*.v"]              { add_v $f }
foreach f [glob "$BUILD_DIR/rtl/chip/tile/l2/rtl/sram_wrappers/*.v"] { add_v $f }

# Common gerado
add_v "$BUILD_DIR/rtl/common/rtl/noc_fbits_splitter.v"
add_v "$BUILD_DIR/rtl/common/rtl/noc_prio_merger.v"
add_v "$BUILD_DIR/rtl/common/rtl/bram_sdp_wrapper.v"

# =============================================================================
# 6. TESTBENCH (fonte de simulação)
# =============================================================================
add_files -fileset sim_1 -norecurse "$TB_DIR/tb_dual_core_cva6.v"
add_files -fileset sim_1 -norecurse "$TB_DIR/stubs.v"
set_property file_type Verilog [get_files -filter {NAME =~ *tb_dual_core_cva6.v}]
set_property file_type Verilog [get_files -filter {NAME =~ *stubs.v}]

# =============================================================================
# 7. APLICAR DEFINES E INCLUDE DIRS
# =============================================================================
set_property verilog_define $SIM_DEFINES [get_filesets sources_1]
set_property verilog_define $SIM_DEFINES [get_filesets sim_1]

set_property include_dirs $INC_DIRS [get_filesets sources_1]
set_property include_dirs $INC_DIRS [get_filesets sim_1]

# =============================================================================
# 8. CONFIGURAR SIMULAÇÃO (xsim)
# =============================================================================
set_property top tb_dual_core_cva6 [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set_property -name {xsim.simulate.runtime} -value {50us} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.wdb} -value {tb_dual_core_cva6.wdb} -objects [get_filesets sim_1]

# =============================================================================
# 9. SALVAR E REPORTAR
# =============================================================================
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts ""
puts "=============================================="
puts " Projeto criado: $PROJ_DIR/$PROJ_NAME.xpr"
puts ""
puts " Para simular via Tcl Console:"
puts "   launch_simulation"
puts "   run 50us"
puts ""
puts " Para abrir o projeto manualmente:"
puts "   open_project $PROJ_DIR/$PROJ_NAME.xpr"
puts "=============================================="
