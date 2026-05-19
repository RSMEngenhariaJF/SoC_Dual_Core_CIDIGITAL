# ============================================================
# run_rw.tcl — Simulação do teste de leitura/escrita (LW+SW)
# Usa boot_rw.hex (gerado por doc/build_rw_test.py)
# em vez do boot.hex padrão.
#
# Uso (batch):
#   vivado -mode batch -source run_rw.tcl -tclargs all
# ============================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]

# Override do binário ANTES de source config.tcl (sourced por run.tcl)
set ::UVM_RUN_BINARY_OVERRIDE \
    [file normalize [file join $SCRIPT_DIR "../../../../" \
    "build/dual_core_cva6/tb/boot_rw.hex"]]

# Fallback: caminho absoluto direto
if {![file exists $::UVM_RUN_BINARY_OVERRIDE]} {
    set ::UVM_RUN_BINARY_OVERRIDE \
        "C:/Users/rafae/Documents/SoC_dual_core/openpiton/build/dual_core_cva6/tb/boot_rw.hex"
}

puts "INFO: R/W test binary: $::UVM_RUN_BINARY_OVERRIDE"

# Delega para o run.tcl principal
source [file join $SCRIPT_DIR "run.tcl"]
