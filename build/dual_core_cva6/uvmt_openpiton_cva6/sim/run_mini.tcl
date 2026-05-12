# =============================================================================
# run_mini.tcl  —  Troca de teste UVM sem recompilar  [Vivado XSim]
#
# MUDANCA em relacao a versao anterior:
#   Antes: rodava o mini_cva6_tb.sv (CVA6 standalone)
#   Agora: troca o UVM_TESTNAME e reinicia a simulacao UVM ja compilada.
#          Nao e necessario re-elaborar — apenas muda o plusarg e reinicia.
#
# Como usar (apos run.tcl ter compilado o projeto):
#   source {D:/CI-Digital/TCC/ProjetoOpenPiton/run_mini.tcl}
#
# Para rodar um teste especifico:
#   set UVM_RUN_TEST "uvmt_opc_coherence_test_c"
#   source run_mini.tcl
#
# Testes disponíveis:
#   uvmt_opc_asm_test_c          — executa um binario assembly (.vmh)
#   uvmt_opc_coherence_test_c    — stress de coerencia multi-tile
#   uvmt_opc_amo_stress_test_c   — stress de operacoes atomicas AMO
# =============================================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]

# Carrega configuracoes (PROJECT_NAME, PROJECT_DIR, UVM_PLUSARGS, etc.)
source [file join $SCRIPT_DIR config.tcl]

# --- Teste a executar (pode ser sobrescrito antes de source run_mini.tcl) ---
if {![info exists UVM_RUN_TEST]} {
    set UVM_RUN_TEST "uvmt_opc_asm_test_c"
}

# --- Binario de teste (pode ser sobrescrito) ---
if {![info exists UVM_TEST_BINARY]} {
    set UVM_TEST_BINARY \
        "$DV_ROOT/verif/diag/assembly/ariane/rv64ui-p-addi.vmh"
}

# --- Verbosidade (pode ser sobrescrito) ---
if {![info exists UVM_VERBOSITY]} {
    set UVM_VERBOSITY "UVM_LOW"
}

puts "INFO: run_mini.tcl UVM"
puts "INFO:   Teste    : $UVM_RUN_TEST"
puts "INFO:   Binario  : $UVM_TEST_BINARY"
puts "INFO:   Verbose  : $UVM_VERBOSITY"

# --- Garante que o projeto esta aberto e compilado ---
if {[llength [get_projects -quiet]] == 0} {
    set xpr_file [file join $PROJECT_DIR "${PROJECT_NAME}.xpr"]
    if {[file exists $xpr_file]} {
        puts "INFO: Abrindo projeto existente: $xpr_file"
        open_project $xpr_file
    } else {
        puts "INFO: Projeto nao encontrado. Executando run.tcl para compilar..."
        source [file join $SCRIPT_DIR run.tcl]
        puts "INFO: Compilacao concluida. Prosseguindo..."
        # run.tcl ja lancou a simulacao; apenas retorna
        return
    }
} else {
    puts "INFO: Projeto ja aberto: [get_projects]"
}

# --- Monta os novos plusargs para este teste ---
# NOTA: Cada -testplusarg e um item separado; o valor inteiro e passado
# via -value {...} para evitar que set_property interprete o "-" como opcao.
set new_plusargs {}
append new_plusargs "-testplusarg {UVM_TESTNAME=$UVM_RUN_TEST} "
append new_plusargs "-testplusarg {UVM_VERBOSITY=$UVM_VERBOSITY} "
append new_plusargs "-testplusarg {TEST_BINARY=$UVM_TEST_BINARY} "
append new_plusargs "-testplusarg {TIMEOUT=5000000}"

set sim_fs [get_filesets sim_1]
set_property -name  xsim.simulate.xsim.more_options \
             -value $new_plusargs \
             -objects $sim_fs
puts "INFO: xsim.more_options: $new_plusargs"

# --- Fecha simulacao anterior se aberta ---
if {[catch {current_sim} _cs] == 0 && $_cs ne ""} {
    puts "INFO: Fechando simulacao anterior..."
    close_sim -force
}

# --- Relanca a simulacao (sem re-elaborar se o design nao mudou) ---
# Se o design nao foi alterado desde a ultima compilacao,
# launch_simulation reusa os artefatos de elaboracao.
puts "INFO: Lancando simulacao UVM: $UVM_RUN_TEST ..."
launch_simulation -simset sim_1 -mode behavioral

# --- Carrega waveform ---
set wave_tcl [file join $SCRIPT_DIR wave.tcl]
if {[file exists $wave_tcl]} { source $wave_tcl }

# --- Executa ---
run $SIM_RUNTIME

puts ""
puts "INFO: ====================================================="
puts "INFO: Teste concluido: $UVM_RUN_TEST"
puts "INFO: Verifique 'HIT GOOD TRAP' ou 'UVM_ERROR' acima."
puts "INFO: ====================================================="
puts ""
puts "INFO: Para rodar outro teste:"
puts "INFO:   set UVM_RUN_TEST uvmt_opc_coherence_test_c"
puts "INFO:   source run_mini.tcl"
puts ""
puts "INFO: Para voltar ao flow completo:"
puts "INFO:   source run.tcl"
