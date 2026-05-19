# ============================================================
# run_math.tcl — Simulação do teste de operações matemáticas
# Usa boot_math.hex (gerado por doc/build_math_test.py)
# em vez do boot.hex padrão.
#
# Uso (batch):
#   vivado -mode batch -source run_math.tcl -tclargs all
# ============================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]

# Override do binário ANTES de source config.tcl (que é sourced por run.tcl)
set ::UVM_RUN_BINARY_OVERRIDE \
    [file normalize [file join $SCRIPT_DIR "../../../../" \
    "build/dual_core_cva6/tb/boot_math.hex"]]

# Fallback: caminho absoluto direto
if {![file exists $::UVM_RUN_BINARY_OVERRIDE]} {
    set ::UVM_RUN_BINARY_OVERRIDE \
        "C:/Users/rafae/Documents/SoC_dual_core/openpiton/build/dual_core_cva6/tb/boot_math.hex"
}

puts "INFO: Math test binary: $::UVM_RUN_BINARY_OVERRIDE"

# Delega para o run.tcl principal
source [file join $SCRIPT_DIR "run.tcl"]
