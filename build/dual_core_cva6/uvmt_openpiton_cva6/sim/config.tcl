# =============================================================================
# config.tcl  --  OpenPiton+CVA6 UVM Environment  [Windows / Vivado XSim]
#
# CORRECOES aplicadas em relacao a versao original:
#   [FIX-1] PROJECT_ROOT hardcoded (D:/CI-Digital/...) substituido por caminhos
#           auto-derivados do SCRIPT_DIR (portavel entre maquinas).
#   [FIX-2] MODEL_DIR agora aponta para build/dual_core_cva6/uvmt_work/.
#   [FIX-3] UVM_TB_DIR agora derivado do SCRIPT_DIR (nao mais hardcoded).
#   [FIX-4] Defines alinhados com o config.tcl funcional do xsim puro:
#             + PITON_CHIP_FPGA        (ausente — controla paths FPGA no tile.v)
#             + PITON_RV64_PLATFORM    (ausente — habilita plataforma RV64)
#             + PITON_RV64_PLIC        (ausente — habilita PLIC RV64)
#             + PITON_RV64_CLINT       (ausente — habilita CLINT RV64)
#             + PITON_RV64_DEBUGUNIT   (ausente — habilita debug unit RV64)
#             + VC707_BOARD            (ausente — define board target)
#             - PITON_PROTO            (removido — nao esta no config funcional)
#             - FPGA_SYN               (removido — usar PITON_FPGA_SYNTH)
#             - PITON_CLKS_SIM         (removido — nao esta no config funcional)
#             - PITONSYS_NO_MC         (removido — pode desabilitar chipset necesario)
#             - PITONSYS_IOCTRL        (removido — nao esta no config funcional)
#   [FIX-5] TEST_BINARY aponta para boot.hex em tb/ (vmh de piton/verif/ excluido
#           do repositorio). Para testes assembly reais, ver comentario na secao
#           de plusargs.
#   [FIX-6] ALL_RTL_FILES: arquivos RTL patched de build/rtl/ tem prioridade
#           sobre os originais de piton/design/ (l15_csm.v, tile.v,
#           dynamic_input_route_request_calc.v, noc_axi4_bridge_*.v).
# =============================================================================

# --- Autodeteccao do SCRIPT_DIR (funciona tanto via run.tcl quanto standalone) ---
if {![info exists SCRIPT_DIR]} {
    set SCRIPT_DIR [file dirname [file normalize [info script]]]
}

# --- Topologia de tiles ---
set X_TILES     2
set Y_TILES     1
set NUM_TILES   [expr {$X_TILES * $Y_TILES}]

# --- Caminhos auto-derivados do SCRIPT_DIR ---
# SCRIPT_DIR = .../openpiton/build/dual_core_cva6/uvmt_openpiton_cva6/sim
# UVM_TB_DIR = .../openpiton/build/dual_core_cva6/uvmt_openpiton_cva6
# BUILD_DIR  = .../openpiton/build/dual_core_cva6
# PITON_ROOT = .../openpiton
# DV_ROOT    = .../openpiton/piton

set UVM_TB_DIR  [file normalize [file join $SCRIPT_DIR ..]]
set BUILD_DIR   [file normalize [file join $SCRIPT_DIR ../..]]
set PITON_ROOT  [file normalize [file join $SCRIPT_DIR ../../../..]]
set DV_ROOT     "$PITON_ROOT/piton"
set ARIANE_ROOT "$DV_ROOT/design/chip/tile/ariane"
set RTL_PATCHED "$BUILD_DIR/rtl"

# Diretorio de saida do projeto Vivado (separado do build do xsim puro)
set MODEL_DIR    "$BUILD_DIR/uvmt_work"
set PROJECT_NAME "openpiton_uvm_2core"
set PROJECT_DIR  "$MODEL_DIR/vivado_project"

# Garante forward slashes (Vivado aceita ambos no Windows, Tcl e mais estavel assim)
foreach _var {UVM_TB_DIR BUILD_DIR PITON_ROOT DV_ROOT ARIANE_ROOT RTL_PATCHED
              MODEL_DIR PROJECT_DIR} {
    set $_var [string map {\\ /} [set $_var]]
}

# MUDANCA 1: top agora e o testbench UVM
set SIM_TOP      "uvmt_opc_tb"
set TOP_NAME     "uvmt_opc_tb"        ;# alias usado pelo novo run.tcl
set ROOT_DIR     $SCRIPT_DIR          ;# raiz do script (sim/)
set RUN_DIR      "$BUILD_DIR/xsim_work" ;# diretório de saída xvlog/xelab/xsim

# Runtime: 50ms @ 100 MHz = 5 M ciclos (suficiente para assembly tests)
set SIM_RUNTIME  "50000us"

# --- Vivado UVM 1.2 embutida ---
set VIVADO_ROOT  [file dirname [file dirname [file normalize \
                     [info nameofexecutable]]]]
set UVM_HOME     "$VIVADO_ROOT/data/xsim/ip/uvm-1.2"

# --- Configuracoes do projeto Vivado ---
# (mantido para compatibilidade com run.tcl)

# =============================================================================
# Defines Verilog / SystemVerilog
#
# [FIX-4] Alinhado com build/dual_core_cva6/config.tcl (versao funcional xsim).
# Adicionados: PITON_CHIP_FPGA, PITON_RV64_PLATFORM/PLIC/CLINT/DEBUGUNIT, VC707_BOARD
# Removidos:   PITON_PROTO, FPGA_SYN, PITON_CLKS_SIM, PITONSYS_NO_MC, PITONSYS_IOCTRL
# Mantidos:    PITON_ARIANE, PITON_FPGA_SYNTH, WT_DCACHE, XSIM, PITON_NO_CHIP_BRIDGE
# UVM-only:    UVM_NO_DPI, UVM_REGEX_NO_DPI (XSim nao suporta DPI)
# Topologia:   PITON_NUM_TILES, PITON_X_TILES, PITON_Y_TILES
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

# --- Diretorios de include RTL (design + ariane + build) ---
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

# --- Diretorios de include UVM testbench ---
set TB_PATHS [list \
    "$UVM_TB_DIR/sv_if"                                              \
    "$UVM_TB_DIR/env"                                                \
    "$UVM_TB_DIR/env/agents/clk_rst"                                 \
    "$UVM_TB_DIR/env/agents/noc"                                     \
    "$UVM_TB_DIR/env/agents/l15_tri"                                 \
    "$UVM_TB_DIR/env/agents/status"                                  \
    "$UVM_TB_DIR/env/agents/uart"                                    \
    "$UVM_TB_DIR/scoreboard"                                         \
    "$UVM_TB_DIR/cov"                                                \
    "$UVM_TB_DIR/seq_lib"                                            \
    "$UVM_TB_DIR/tests"                                              \
]

# Mantido para compatibilidade com qualquer código legado que use ALL_INC_DIRS
set ALL_INC_DIRS [concat $RTL_PATHS $TB_PATHS]

# --- Arquivos de cabecalho RTL ---
set ALL_INC_FILES [list \
    "$SCRIPT_DIR/xsim_compat.vh"                                  \
    "$DV_ROOT/design/include/define.h"                            \
    "$DV_ROOT/design/include/piton_system.vh"                     \
    "$DV_ROOT/design/include/dmbr_define.v"                       \
    "$DV_ROOT/design/include/l15.h"                               \
    "$DV_ROOT/design/include/l2.h"                                \
    "$DV_ROOT/design/include/network_define.v"                    \
    "$DV_ROOT/design/include/jtag.vh"                             \
    "$DV_ROOT/design/include/ifu.h"                               \
    "$DV_ROOT/design/include/lsu.h"                               \
    "$DV_ROOT/design/chipset/include/chipset_define.vh"           \
]

# =============================================================================
# Arquivos RTL do design
#
# [FIX-6] Para arquivos com patch aplicado (l15_csm.v, tile.v,
# dynamic_input_route_request_calc.v, noc_axi4_bridge_*.v), a versao em
# build/dual_core_cva6/rtl/ tem prioridade sobre a original em piton/design/.
# O proc select_rtl abaixo implementa essa logica.
# =============================================================================
proc select_rtl {patched_root orig_path} {
    # Se existe versao patched em build/rtl/, usa ela; caso contrario usa original.
    set rel [regsub {.*/piton/design/} $orig_path ""]
    set patched [file join $patched_root $rel]
    if {[file exists $patched]} {
        return $patched
    }
    return $orig_path
}

# Helper para construir lista de RTL com preferencia pelas versoes patched
proc rtl {patched_root path} {
    return [select_rtl $patched_root $path]
}

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
    "$RTL_PATCHED/chipset/rtl/storage_addr_trans.v"                                                           \
    "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/axi4_zeroer.v"                                              \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge.v"]                       \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_deser.v"]                 \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_write.v"]                 \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_read.v"]                  \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_buffer.v"]                \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_ser.v"]                   \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_sram_data.v"]             \
    [rtl $RTL_PATCHED "$DV_ROOT/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_sram_req.v"]              \
    "$BUILD_DIR/tb/protocol_adapter.v"                                                                        \
    "$BUILD_DIR/tb/axi4_sram_model.v"                                                                         \
]

# --- Arquivos do ambiente UVM (sim_1 apenas) ---
set ALL_UVM_TB_FILES [list \
    "$UVM_TB_DIR/sv_if/uvmt_opc_clk_rst_if.sv" \
    "$UVM_TB_DIR/sv_if/uvmt_opc_noc_if.sv"      \
    "$UVM_TB_DIR/sv_if/uvmt_opc_l15_tri_if.sv"  \
    "$UVM_TB_DIR/sv_if/uvmt_opc_status_if.sv"   \
    "$UVM_TB_DIR/env/uvmt_opc_pkg.sv"            \
    "$UVM_TB_DIR/tb/uvmt_opc_dut_wrap.sv"        \
    "$UVM_TB_DIR/tb/uvmt_opc_tb.sv"              \
]

# --- Configuracao UVM (usada por parse_uvm_args em run.tcl) ---
set UVM_TEST       "uvmt_opc_asm_test_c"
set UVM_VERBOSITY  "UVM_LOW"
set RND_SEED       ""
set UVM_TIMEOUT    "5000000"
set UVM_ARGS       {}   ;# preenchido por parse_uvm_args

# TEST_BINARY [FIX-5]:
#   piton/verif/diag/assembly/ esta excluido do repositorio (489 MB).
#   Usando boot.hex como placeholder (jal x0,0 em 0x80000000).
#   Para testes assembly reais, defina antes de source run.tcl:
#     set UVM_RUN_BINARY "C:/caminho/para/rv64ui-p-addi.vmh"
set UVM_RUN_BINARY "$BUILD_DIR/tb/boot.hex"
if {[info exists ::UVM_RUN_BINARY_OVERRIDE]} {
    set UVM_RUN_BINARY $::UVM_RUN_BINARY_OVERRIDE
}

# Mantido para compatibilidade
set UVM_PLUSARGS [list \
    "UVM_TESTNAME=$UVM_TEST"            \
    "UVM_VERBOSITY=$UVM_VERBOSITY"      \
    "TEST_BINARY=$UVM_RUN_BINARY"       \
    "TIMEOUT=$UVM_TIMEOUT"              \
]

# --- Arquivos do TB original OpenPiton (referencia, nao usados no flow UVM) ---
set ALL_TB_FILES_ORIGINAL [list \
    "$DV_ROOT/verif/env/manycore/manycore_top.v"  \
    "$DV_ROOT/verif/env/manycore/fake_pll.v"      \
    "$DV_ROOT/verif/env/manycore/fake_uart.v"     \
]

# --- Arquivos SV do CVA6/Ariane (lidos do Flist.ariane) ---
set ALL_SV_FILES {}
set flist_path "$ARIANE_ROOT/Flist.ariane"
if {[file exists $flist_path]} {
    set fd [open $flist_path r]
    while {[gets $fd line] >= 0} {
        set line [string trim $line]
        if {$line eq "" || [string match "//*" $line] || \
            [string match "+incdir+*" $line]} { continue }
        set sv_path "$ARIANE_ROOT/$line"
        lappend ALL_SV_FILES [string map {\\ /} $sv_path]
    }
    close $fd
} else {
    puts "AVISO: Flist.ariane nao encontrado em $flist_path"
}

# --- Python para PyHP preprocessing ---
# VIVADO_ROOT = .../Vivado (ex: C:/Xilinx/2025.1/Vivado)
# Python do Vivado esta em $parent/tps/win64/python-X.Y.Z/python.exe
# onde $parent = file dirname $VIVADO_ROOT (ex: C:/Xilinx/2025.1)
set PYTHON_EXE ""
set _vivado_parent [file dirname $VIVADO_ROOT]
foreach _py_glob [glob -nocomplain \
        [file join $_vivado_parent tps win64 python-* python.exe]] {
    if {[file exists $_py_glob]} { set PYTHON_EXE $_py_glob; break }
}
# Fallback: Python local (excluindo Windows Store stubs que nao funcionam via exec)
if {$PYTHON_EXE eq ""} {
    foreach _py_candidate {
            {C:/Users/rafae/AppData/Local/Python/bin/python.exe}
            {C:/Python312/python.exe} {C:/Python311/python.exe}
            {C:/Python310/python.exe} } {
        if {[file exists $_py_candidate] && \
            ![catch {exec $_py_candidate --version} _v]} {
            set PYTHON_EXE $_py_candidate; break
        }
    }
}
if {$PYTHON_EXE ne ""} {
    puts "INFO: Python encontrado: $PYTHON_EXE"
} else {
    puts "AVISO: Python nao encontrado — preprocessing precisara de PYTHON_EXE manual"
}

# --- Listas de compilacao para o flow xvlog/xelab/xsim ---
# ALL_SV_FILES (Ariane/CVA6) + ALL_RTL_FILES (OpenPiton) → compilados juntos
set XVLOG_RTL_FILES [concat $ALL_SV_FILES $ALL_RTL_FILES]
set XVLOG_TB_FILES  $ALL_UVM_TB_FILES
set XVHDL_RTL_FILES {}
set XVHDL_TB_FILES  {}

puts "INFO: config.tcl carregado (modo UVM) -- $NUM_TILES nucleo(s) \[$X_TILES x $Y_TILES\]"
puts "INFO: PITON_ROOT  = $PITON_ROOT"
puts "INFO: BUILD_DIR   = $BUILD_DIR"
puts "INFO: UVM_TB_DIR  = $UVM_TB_DIR"
puts "INFO: RUN_DIR     = $RUN_DIR"
puts "INFO: RTL_PATCHED = $RTL_PATCHED"
puts "INFO: SIM_TOP     = $SIM_TOP"
puts "INFO: CVA6 SV     : [llength $ALL_SV_FILES] arquivos"
puts "INFO: RTL files   : [llength $ALL_RTL_FILES] arquivos"
puts "INFO: UVM files   : [llength $ALL_UVM_TB_FILES] arquivos"
puts "INFO: TEST_BINARY : $UVM_RUN_BINARY"
