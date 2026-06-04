# =============================================================================
# config.tcl  --  OpenPiton+CVA6 UVM V2 Coherence Testbench [Windows/XSim]
#
# Baseado em uvmt_openpiton_cva6/sim/config.tcl com as seguintes alterações:
#   [V2-1] UVM_TB_DIR aponta para uvmt_openpiton_cva6_v2 (este diretório)
#   [V2-2] UVM_TEST = uvmt_opc_coh2_test_c (teste v2 com config_db fix)
#   [V2-3] TOP_NAME = uvmt_opc_coh2_tb (TB top v2)
#   [V2-4] RUN_DIR = xsim_work_v2 (separado do v1 para não sobrescrever)
#   [V2-5] XVLOG_TB_FILES inclui:
#            - sv_if v1 (mesmas interfaces básicas)
#            - sv_if v2: uvmt_opc_sb_mon_if.sv (nova)
#            - uvmt_opc_pkg.sv (pacote v1 - compilado primeiro)
#            - uvmt_opc_coh2_pkg.sv (pacote v2 - importa o v1)
#            - tb v2: uvmt_opc_coh2_dut_wrap.sv + uvmt_opc_coh2_tb.sv
# =============================================================================

if {![info exists SCRIPT_DIR]} {
    set SCRIPT_DIR [file dirname [file normalize [info script]]]
}

# --- Topologia de tiles ---
set X_TILES   2
set Y_TILES   1
set NUM_TILES [expr {$X_TILES * $Y_TILES}]

# --- Caminhos auto-derivados ---
# SCRIPT_DIR = .../uvmt_openpiton_cva6_v2/sim
# V2_TB_DIR  = .../uvmt_openpiton_cva6_v2
# V1_TB_DIR  = .../uvmt_openpiton_cva6       (pacote v1 reutilizado)
# BUILD_DIR  = .../dual_core_cva6
# PITON_ROOT = .../openpiton

set UVM_TB_DIR  [file normalize [file join $SCRIPT_DIR ..]]
set V1_TB_DIR   [file normalize [file join $SCRIPT_DIR "../../uvmt_openpiton_cva6"]]
set BUILD_DIR   [file normalize [file join $SCRIPT_DIR "../.."]]
set PITON_ROOT  [file normalize [file join $SCRIPT_DIR "../../../../"]]
set DV_ROOT     "$PITON_ROOT/piton"
set ARIANE_ROOT "$DV_ROOT/design/chip/tile/ariane"
set RTL_PATCHED "$BUILD_DIR/rtl"

set MODEL_DIR    "$BUILD_DIR/uvmt_work"
set PROJECT_NAME "openpiton_uvm_v2"
set PROJECT_DIR  "$MODEL_DIR/vivado_project_v2"

# [V2-4] Diretório de saída separado do v1
set RUN_DIR "$BUILD_DIR/xsim_work_v2"

foreach _var {UVM_TB_DIR V1_TB_DIR BUILD_DIR PITON_ROOT DV_ROOT ARIANE_ROOT
              RTL_PATCHED MODEL_DIR PROJECT_DIR RUN_DIR} {
    set $_var [string map {\\ /} [set $_var]]
}

# [V2-3] Top do testbench v2
set SIM_TOP  "uvmt_opc_coh2_tb"
set TOP_NAME "uvmt_opc_coh2_tb"
set ROOT_DIR $SCRIPT_DIR
set SIM_RUNTIME "50000us"

set VIVADO_ROOT [file dirname [file dirname [file normalize \
                    [info nameofexecutable]]]]
set UVM_HOME    "$VIVADO_ROOT/data/xsim/ip/uvm-1.2"

# =============================================================================
# Defines Verilog (idênticos ao v1)
# =============================================================================
set ALL_VERILOG_DEFINES [list \
    "PITON_NUM_TILES=$NUM_TILES"  \
    "PITON_X_TILES=$X_TILES"     \
    "PITON_Y_TILES=$Y_TILES"     \
    "PITON_ARIANE"               \
    "PITON_CHIP_FPGA"            \
    "PITON_FPGA_SYNTH"           \
    "WT_DCACHE"                  \
    "PITON_RV64_PLATFORM"        \
    "PITON_RV64_PLIC"            \
    "PITON_RV64_CLINT"           \
    "PITON_RV64_DEBUGUNIT"       \
    "XSIM"                       \
    "PITON_NO_CHIP_BRIDGE"       \
    "PITON_NO_JTAG"              \
    "NO_SCAN"                    \
    "VC707_BOARD"                \
    "UVM_NO_DPI"                 \
    "UVM_REGEX_NO_DPI"           \
]

# --- Includes RTL (idênticos ao v1) ---
set RTL_PATHS [list \
    "$DV_ROOT/design/include"                                        \
    "$DV_ROOT/design/chipset/include"                                \
    "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl"                   \
    "$DV_ROOT/verif/env/manycore"                                    \
    "$ARIANE_ROOT/common/submodules/common_cells/include"            \
    "$ARIANE_ROOT/common/local/util"                                 \
    "$ARIANE_ROOT/corev_apu/register_interface/include"              \
    "$BUILD_DIR/include"                                             \
    "$RTL_PATCHED"                                                   \
]

# [V2-5] Includes UVM: v1 + v2
set TB_PATHS [list \
    "$V1_TB_DIR/sv_if"                      \
    "$UVM_TB_DIR/sv_if"                     \
    "$V1_TB_DIR/env"                        \
    "$V1_TB_DIR/env/agents/clk_rst"         \
    "$V1_TB_DIR/env/agents/noc"             \
    "$V1_TB_DIR/env/agents/l15_tri"         \
    "$V1_TB_DIR/env/agents/status"          \
    "$V1_TB_DIR/env/agents/uart"            \
    "$V1_TB_DIR/scoreboard"                 \
    "$V1_TB_DIR/cov"                        \
    "$V1_TB_DIR/seq_lib"                    \
    "$V1_TB_DIR/tests"                      \
    "$UVM_TB_DIR/env"                       \
    "$UVM_TB_DIR/env/agents/sb_mon"         \
    "$UVM_TB_DIR/scoreboard"                \
    "$UVM_TB_DIR/seq_lib"                   \
    "$UVM_TB_DIR/tests"                     \
]

set ALL_INC_DIRS [concat $RTL_PATHS $TB_PATHS]

# --- Headers RTL (idênticos ao v1) ---
set ALL_INC_FILES [list \
    "$V1_TB_DIR/sim/xsim_compat.vh"                              \
    "$DV_ROOT/design/include/define.h"                           \
    "$DV_ROOT/design/include/piton_system.vh"                    \
    "$DV_ROOT/design/include/dmbr_define.v"                      \
    "$DV_ROOT/design/include/l15.h"                              \
    "$DV_ROOT/design/include/l2.h"                               \
    "$DV_ROOT/design/include/network_define.v"                   \
    "$DV_ROOT/design/include/jtag.vh"                            \
    "$DV_ROOT/design/include/ifu.h"                              \
    "$DV_ROOT/design/include/lsu.h"                              \
    "$DV_ROOT/design/chipset/include/chipset_define.vh"          \
]

# =============================================================================
# Arquivos RTL (idênticos ao v1 — mesmo DUT)
# =============================================================================
proc select_rtl {patched_root orig_path} {
    set rel [regsub {.*/piton/design/} $orig_path ""]
    set patched [file join $patched_root $rel]
    if {[file exists $patched]} { return $patched }
    return $orig_path
}
proc rtl {patched_root path} { return [select_rtl $patched_root $path] }

set ALL_RTL_FILES [list \
    "$BUILD_DIR/tb/stubs.v"                                                        \
    [rtl $RTL_PATCHED "$DV_ROOT/design/rtl/system.v"]                              \
    "$DV_ROOT/design/common/rtl/async_fifo.v"                                      \
    "$DV_ROOT/design/common/rtl/sync_fifo_vr.v"                                    \
    "$DV_ROOT/design/common/rtl/noc_simple_merger.v"                               \
    "$DV_ROOT/design/common/rtl/noc_simple_splitter.v"                             \
    [rtl $RTL_PATCHED "$DV_ROOT/design/common/rtl/bram_sdp_wrapper.v"]             \
    [rtl $RTL_PATCHED "$DV_ROOT/design/common/rtl/bram_1rw_wrapper.v"]             \
    [rtl $RTL_PATCHED "$DV_ROOT/design/common/rtl/bram_1r1w_wrapper.v"]            \
    [rtl $RTL_PATCHED "$DV_ROOT/design/common/rtl/synchronizer.v"]                 \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/rtl/OCI.v"]                            \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/rtl/chip.v"]                           \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/pll/rtl/clk_mux.v"]                   \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/pll/rtl/clk_se_to_diff.v"]            \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/jtag/rtl/jtag.v"]                     \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/jtag/rtl/jtag_interface_tap.v"]       \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/jtag/rtl/jtag_ucb_transmitter.v"]     \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/jtag/rtl/jtag_ucb_receiver.v"]        \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/jtag/rtl/jtag_interface.v"]           \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/jtag/rtl/jtag_ctap.v"]                \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/chip_bridge/rtl/chip_bridge.v"]       \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/chip_bridge/rtl/chip_bridge_send_32.v"] \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/chip_bridge/rtl/chip_bridge_rcv_32.v"]  \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/chip_bridge/rtl/sync_fifo.v"]         \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/chip_bridge/rtl/chip_net_chooser_32.v"] \
    "$DV_ROOT/design/chip/tile/common/rtl/swrvr_clib.v"                           \
    "$DV_ROOT/design/chip/tile/common/rtl/clk_gating_latch.v"                     \
    "$DV_ROOT/design/chip/tile/common/rtl/credit_to_valrdy.v"                     \
    "$DV_ROOT/design/chip/tile/common/rtl/valrdy_to_credit.v"                     \
    "$DV_ROOT/design/chip/tile/common/rtl/ucb_bus_in.v"                           \
    "$DV_ROOT/design/chip/tile/common/rtl/ucb_bus_out.v"                          \
    "$DV_ROOT/design/chip/tile/common/rtl/ucb_flow_2buf.v"                        \
    "$DV_ROOT/design/chip/tile/common/rtl/ucb_noflow.v"                           \
    "$DV_ROOT/design/chip/tile/common/rtl/dbl_buf.v"                              \
    "$RTL_PATCHED/chip/tile/common/rtl/flat_id_to_xy.v"                           \
    "$RTL_PATCHED/chip/tile/common/rtl/xy_to_flat_id.v"                           \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/dmbr/rtl/dmbr.v"]                \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/rtl/tile.v"]                     \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/rtl/config_regs.v"]              \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/rtl/cpx_arbitrator.v"]           \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/rtl/ccx_l15_transducer.v"]       \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/rtl/pico_l15_transducer.v"]      \
    "$DV_ROOT/design/chip/tile/dynamic_node/components/rtl/bus_compare_equal.v"   \
    "$DV_ROOT/design/chip/tile/dynamic_node/components/rtl/flip_bus.v"            \
    "$DV_ROOT/design/chip/tile/dynamic_node/components/rtl/net_dff.v"             \
    "$DV_ROOT/design/chip/tile/dynamic_node/components/rtl/one_of_five.v"         \
    "$DV_ROOT/design/chip/tile/dynamic_node/components/rtl/one_of_eight.v"        \
    "$DV_ROOT/design/chip/tile/dynamic_node/common/rtl/network_input_blk_multi_out.v" \
    "$DV_ROOT/design/chip/tile/dynamic_node/common/rtl/space_avail_top.v"         \
    "$DV_ROOT/design/chip/tile/dynamic_node/dynamic/rtl/dynamic_input_control.v"  \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/dynamic_node/dynamic/rtl/dynamic_input_route_request_calc.v"] \
    "$DV_ROOT/design/chip/tile/dynamic_node/dynamic/rtl/dynamic_input_top_4.v"    \
    "$DV_ROOT/design/chip/tile/dynamic_node/dynamic/rtl/dynamic_input_top_16.v"   \
    "$DV_ROOT/design/chip/tile/dynamic_node/dynamic/rtl/dynamic_output_control.v" \
    "$DV_ROOT/design/chip/tile/dynamic_node/dynamic/rtl/dynamic_output_datapath.v" \
    "$DV_ROOT/design/chip/tile/dynamic_node/dynamic/rtl/dynamic_output_top.v"     \
    "$DV_ROOT/design/chip/tile/dynamic_node/rtl/dynamic_node_top.v"               \
    "$DV_ROOT/design/chip/tile/dynamic_node/rtl/dynamic_node_top_wrap.v"          \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l15/rtl/l15_csm.v"]              \
    "$RTL_PATCHED/chip/tile/l15/rtl/l15_hmc.v"                                    \
    "$RTL_PATCHED/chip/tile/l15/rtl/l15_home_encoder.v"                           \
    "$RTL_PATCHED/chip/tile/l15/rtl/l15_mshr.v"                                   \
    "$RTL_PATCHED/chip/tile/l15/rtl/l15_pipeline.v"                               \
    "$RTL_PATCHED/chip/tile/l15/rtl/l15_priority_encoder.v"                       \
    "$RTL_PATCHED/chip/tile/l15/rtl/noc1buffer.v"                                 \
    "$RTL_PATCHED/chip/tile/l15/rtl/rf_l15_lrsc_flag.v"                           \
    "$RTL_PATCHED/chip/tile/l15/rtl/rf_l15_lruarray.v"                            \
    "$RTL_PATCHED/chip/tile/l15/rtl/rf_l15_mesi.v"                                \
    "$RTL_PATCHED/chip/tile/l15/rtl/rf_l15_wmt.v"                                 \
    "$RTL_PATCHED/chip/tile/l15/rtl/sram_wrappers/sram_l15_data.v"                \
    "$RTL_PATCHED/chip/tile/l15/rtl/sram_wrappers/sram_l15_hmt.v"                 \
    "$RTL_PATCHED/chip/tile/l15/rtl/sram_wrappers/sram_l15_tag.v"                 \
    "$DV_ROOT/design/chip/tile/l15/rtl/simplenocbuffer.v"                         \
    "$DV_ROOT/design/chip/tile/l15/rtl/noc2decoder.v"                             \
    "$DV_ROOT/design/chip/tile/l15/rtl/pcx_buffer.v"                              \
    "$DV_ROOT/design/chip/tile/l15/rtl/pcx_decoder.v"                             \
    "$DV_ROOT/design/chip/tile/l15/rtl/pico_decoder.v"                            \
    "$DV_ROOT/design/chip/tile/l15/rtl/l15_picoencoder.v"                         \
    "$DV_ROOT/design/chip/tile/l15/rtl/l15_cpxencoder.v"                          \
    "$DV_ROOT/design/chip/tile/l15/rtl/noc1encoder.v"                             \
    "$DV_ROOT/design/chip/tile/l15/rtl/noc3buffer.v"                              \
    "$DV_ROOT/design/chip/tile/l15/rtl/noc3encoder.v"                             \
    "$DV_ROOT/design/chip/tile/l15/rtl/l15.v"                                     \
    "$DV_ROOT/design/chip/tile/l15/rtl/l15_wrap.v"                                \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_priority_encoder.v"]   \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_data_pgen.v"]          \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_data_ecc.v"]           \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_smc.v"]                \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe2_dpath.v"]        \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe2_ctrl.v"]         \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe2_buf_in.v"]       \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe1_dpath.v"]        \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe1_ctrl.v"]         \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe1_buf_out.v"]      \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe1_buf_in.v"]       \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_mshr_decoder.v"]       \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_mshr.v"]               \
    "$DV_ROOT/design/chip/tile/l2/rtl/l2_amo_alu.v"                               \
    "$DV_ROOT/design/chip/tile/l2/rtl/l2_data.v"                                  \
    "$DV_ROOT/design/chip/tile/l2/rtl/l2_data_wrap.v"                             \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_encoder.v"]            \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_decoder.v"]            \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_broadcast_counter.v"]  \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_smc_wrap.v"]           \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe2.v"]              \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_pipe1.v"]              \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_mshr_wrap.v"]          \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_config_regs.v"]        \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_broadcast_counter_wrap.v"] \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_tag_wrap.v"]           \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_state_wrap.v"]         \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_dir_wrap.v"]           \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_tag.v"]                \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_state.v"]              \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2_dir.v"]                \
    "$RTL_PATCHED/chip/tile/l2/rtl/sram_wrappers/sram_l2_data.v"                  \
    "$RTL_PATCHED/chip/tile/l2/rtl/sram_wrappers/sram_l2_dir.v"                   \
    "$RTL_PATCHED/chip/tile/l2/rtl/sram_wrappers/sram_l2_state.v"                 \
    "$RTL_PATCHED/chip/tile/l2/rtl/sram_wrappers/sram_l2_tag.v"                   \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chip/tile/l2/rtl/l2.v"]                    \
    "$DV_ROOT/design/chip/tile/rtap/rtl/rtap_ucb_receiver.v"                      \
    "$DV_ROOT/design/chip/tile/rtap/rtl/rtap_ucb_transmitter.v"                   \
    "$DV_ROOT/design/chip/tile/rtap/rtl/rtap.v"                                   \
    "$RTL_PATCHED/common/rtl/noc_fbits_splitter.v"                                 \
    "$RTL_PATCHED/common/rtl/noc_prio_merger.v"                                    \
    "$RTL_PATCHED/chipset/rtl/storage_addr_trans.v"                                \
    "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/axi4_zeroer.v"                   \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge.v"]       \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_deser.v"] \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_write.v"] \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_read.v"]  \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_buffer.v"] \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_ser.v"]   \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_sram_data.v"] \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_sram_req.v"]  \
    "$BUILD_DIR/tb/protocol_adapter.v"                                             \
    "$BUILD_DIR/tb/axi4_sram_model.v"                                              \
]

# --- [V2-5] Arquivos UVM do testbench v2 ---
set ALL_UVM_TB_FILES [list \
    "$V1_TB_DIR/sv_if/uvmt_opc_clk_rst_if.sv"    \
    "$V1_TB_DIR/sv_if/uvmt_opc_noc_if.sv"         \
    "$V1_TB_DIR/sv_if/uvmt_opc_l15_tri_if.sv"     \
    "$V1_TB_DIR/sv_if/uvmt_opc_status_if.sv"      \
    "$UVM_TB_DIR/sv_if/uvmt_opc_sb_mon_if.sv"     \
    "$V1_TB_DIR/env/uvmt_opc_pkg.sv"              \
    "$UVM_TB_DIR/env/uvmt_opc_coh2_pkg.sv"        \
    "$UVM_TB_DIR/tb/uvmt_opc_coh2_dut_wrap.sv"    \
    "$UVM_TB_DIR/tb/uvmt_opc_coh2_tb.sv"          \
]

# --- Python para PyHP (mesmo do v1) ---
set PYTHON_EXE ""
set _vivado_parent [file dirname $VIVADO_ROOT]
foreach _py_glob [glob -nocomplain \
        [file join $_vivado_parent tps win64 python-* python.exe]] {
    if {[file exists $_py_glob]} { set PYTHON_EXE $_py_glob; break }
}
if {$PYTHON_EXE eq ""} {
    foreach _py_candidate {
            {C:/Users/rafae/AppData/Local/Python/bin/python.exe}
            {C:/Python312/python.exe} {C:/Python311/python.exe}} {
        if {[file exists $_py_candidate] && \
            ![catch {exec $_py_candidate --version} _v]} {
            set PYTHON_EXE $_py_candidate; break
        }
    }
}

# --- Configuração UVM ---
set UVM_TEST      "uvmt_opc_coh2_test_c"
if {[info exists ::UVM_TEST_OVERRIDE]} { set UVM_TEST $::UVM_TEST_OVERRIDE }
set UVM_VERBOSITY "UVM_LOW"
set RND_SEED      ""
set UVM_TIMEOUT   "20000"
set UVM_ARGS      {}

set UVM_RUN_BINARY "$BUILD_DIR/tb/boot_e3.hex"
if {[info exists ::UVM_RUN_BINARY_OVERRIDE]} {
    set UVM_RUN_BINARY $::UVM_RUN_BINARY_OVERRIDE
}

# --- Listas para xvlog/xelab ---
set ALL_SV_FILES {}
set flist_path "$ARIANE_ROOT/Flist.ariane"
if {[file exists $flist_path]} {
    set fd [open $flist_path r]
    while {[gets $fd line] >= 0} {
        set line [string trim $line]
        if {$line eq "" || [string match "//*" $line] ||
            [string match "+incdir+*" $line]} { continue }
        lappend ALL_SV_FILES [string map {\\ /} "$ARIANE_ROOT/$line"]
    }
    close $fd
}

set XVLOG_RTL_FILES [concat $ALL_SV_FILES $ALL_RTL_FILES]
set XVLOG_TB_FILES  $ALL_UVM_TB_FILES
set XVHDL_RTL_FILES {}
set XVHDL_TB_FILES  {}

puts "INFO: config.tcl V2 carregado -- $NUM_TILES nucleo(s) \[$X_TILES x $Y_TILES\]"
puts "INFO: V1_TB_DIR  = $V1_TB_DIR"
puts "INFO: V2_TB_DIR  = $UVM_TB_DIR"
puts "INFO: RUN_DIR    = $RUN_DIR (separado do v1)"
puts "INFO: TOP        = $TOP_NAME"
puts "INFO: UVM_TEST   = $UVM_TEST"
puts "INFO: UVM files  : [llength $ALL_UVM_TB_FILES] (v1 + v2)"
