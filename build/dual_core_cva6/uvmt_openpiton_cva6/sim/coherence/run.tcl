# =============================================================================
# sim/coherence/run.tcl
# Entrada para o teste de coerencia de cache (FALSE_SHARING)
#
# Padrao: Hart 0 e Hart 1 escrevem em words distintas dentro da MESMA linha
# de cache (0x80002000..0x8000203F), exercitando false sharing na L1 DCache
# e os mecanismos de coerencia L1.5 / NoC P-Mesh.
#
# Teste UVM: uvmt_opc_coherence_test_c
#   - finish_mask=0x3 (scoreboard exige que tiles 0 E 1 completem)
#   - enable_coh_check=1 (verifica mensagens INVAL_REQ/INVAL_ACK no NoC)
#
# Binario: boot_coherence.hex (gerado por doc/build_coherence_test.py)
#
# Uso (batch, a partir desta pasta):
#   vivado -mode batch -source run.tcl -tclargs run
#   vivado -mode batch -source run.tcl -tclargs all    (compile+elaborate+run)
#
# Uso (interativo no Vivado TCL):
#   cd .../sim/coherence
#   set SCRIPT_TARGET run
#   source run.tcl
#
# Para recompilar do zero:
#   vivado -mode batch -source run.tcl -tclargs all
# =============================================================================

set THIS_DIR [file dirname [file normalize [info script]]]
set SIM_DIR  [file normalize [file join $THIS_DIR ..]]

# --- Binario de teste ---
set ::UVM_RUN_BINARY_OVERRIDE \
    [file normalize [file join $THIS_DIR "../../tb/boot_coherence.hex"]]

# Fallback para caminho absoluto caso o relativo nao resolva
if {![file exists $::UVM_RUN_BINARY_OVERRIDE]} {
    set ::UVM_RUN_BINARY_OVERRIDE \
        "C:/Users/rafae/Documents/SoC_dual_core/openpiton/build/dual_core_cva6/tb/boot_coherence.hex"
}

if {![file exists $::UVM_RUN_BINARY_OVERRIDE]} {
    error "boot_coherence.hex nao encontrado. Execute primeiro:\n  python doc/build_coherence_test.py"
}

# --- Teste UVM de coerencia ---
set ::UVM_TEST_OVERRIDE "uvmt_opc_coherence_test_c"

puts "INFO: =================================================="
puts "INFO:  Teste de Coerencia de Cache -- FALSE_SHARING"
puts "INFO:  Binario : $::UVM_RUN_BINARY_OVERRIDE"
puts "INFO:  Teste   : $::UVM_TEST_OVERRIDE"
puts "INFO: =================================================="

# --- Herda SCRIPT_TARGET de quem chamou (ou define padrao "run") ---
if {![info exists SCRIPT_TARGET]} {
    if {[info exists ::argv] && [llength $::argv] > 0} {
        set SCRIPT_TARGET [lindex $::argv 0]
    } else {
        set SCRIPT_TARGET "run"
    }
}

# --- Delega para o run.tcl principal em sim/ ---
# NOTA: [info script] dentro de run.tcl retorna o path de run.tcl,
# portanto SCRIPT_DIR la dentro sera sim/ — todos os paths relativos
# continuam corretos.
source [file join $SIM_DIR run.tcl]
