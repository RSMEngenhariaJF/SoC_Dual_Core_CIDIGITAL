# ============================================================
# run.tcl  --  OpenPiton+CVA6 UVM V2 Coherence Testbench
#
# Idêntico ao run.tcl v1. O SCRIPT_DIR auto-detectado aponta
# para esta pasta (sim/), que contém o config.tcl v2.
# Portanto sourcing config.tcl carrega automaticamente as
# definições v2 (TOP_NAME=uvmt_opc_coh2_tb, RUN_DIR=xsim_work_v2).
#
# Uso:
#   vivado -mode batch -source run.tcl -tclargs all
#   vivado -mode batch -source run.tcl -tclargs compile
#   vivado -mode batch -source run.tcl -tclargs elaborate
#   vivado -mode batch -source run.tcl -tclargs run
#
# Variáveis opcionais (definir antes de source):
#   set UVM_TEST_OVERRIDE    "uvmt_opc_coh2_test_c"
#   set UVM_RUN_BINARY_OVERRIDE "C:/path/to/coherence_v2.hex"
# ============================================================

# Auto-detecção do diretório do script (aponta para sim/ desta pasta)
set SCRIPT_DIR [file dirname [file normalize [info script]]]

# Carrega configuração v2 (config.tcl nesta mesma pasta)
source [file join $SCRIPT_DIR config.tcl]

# ========================== INIT ============================
set CUR_DATE [clock format [clock seconds] -format "|%Y/%m/%d %H:%M:%S|"]

# ========================== PREPROCESSING ===================
proc run_pyhp {python_cmd pyhp_script in_file out_file} {
    set in_file     [file nativename $in_file]
    set out_file    [file nativename $out_file]
    set pyhp_script [file nativename $pyhp_script]
    puts "INFO: Preprocessando [file tail $in_file] ..."
    if {[catch {set conteudo [exec $python_cmd $pyhp_script $in_file]} err]} {
        error "Erro no PyHP ao processar $in_file:\n$err"
    }
    if {[string index $conteudo 0] eq "﻿"} {
        set conteudo [string range $conteudo 1 end]
    }
    file mkdir [file dirname $out_file]
    set fd [open $out_file w]
    fconfigure $fd -encoding utf-8 -translation lf
    puts $fd $conteudo
    close $fd
}

proc find_files_recursive {dir pattern} {
    set result {}
    foreach f [glob -nocomplain -type f -directory $dir $pattern] {
        lappend result $f
    }
    foreach subdir [glob -nocomplain -type d -directory $dir *] {
        foreach f [find_files_recursive $subdir $pattern] {
            lappend result $f
        }
    }
    return $result
}

proc run_all_preprocessing {python_cmd pyhp_script dv_root num_tiles x_tiles y_tiles} {
    set ::env(PITON_NUM_TILES) $num_tiles
    set ::env(PITON_X_TILES)   $x_tiles
    set ::env(PITON_Y_TILES)   $y_tiles
    set ::env(PTON_NUM_TILES)  $num_tiles
    set ::env(PITON_ROOT)      [file dirname $dv_root]
    set ::env(DV_ROOT)         $dv_root
    set ::env(PROTOSYN_RUNTIME_DESIGN_PATH) [file join $dv_root design include]
    set ::env(PROTOSYN_RUNTIME_BOARD) ""
    global ALL_VERILOG_DEFINES
    set defines_str [join $ALL_VERILOG_DEFINES " "]
    if {[string match "*PITON_ARIANE*" $defines_str]} {
        set ::env(PITON_ARIANE) 1
    } else {
        set ::env(PITON_ARIANE) 0
    }
    set total 0
    foreach dir [list "$dv_root/design"] {
        foreach pyv [find_files_recursive $dir "*.v.pyv"] {
            run_pyhp $python_cmd $pyhp_script $pyv [string range $pyv 0 end-4]
            incr total
        }
    }
    puts "INFO: Preprocessing: $total .v.pyv"
}

# Verifica se preprocessing é necessário (mesmo critério do v1)
set V1_SIM_DIR [file normalize [file join $SCRIPT_DIR "../../uvmt_openpiton_cva6/sim"]]
set _PYHP_SCRIPT [file join $DV_ROOT tools bin pyhp.py]
set _PREPROC_REQUIRED [list \
    [file join $DV_ROOT design include define.h]      \
    [file join $DV_ROOT design include define.tmp.h]  \
    [select_rtl $RTL_PATCHED [file join $DV_ROOT design chip rtl chip.v]] \
]

set _precisa_preprocessar 0
foreach _f $_PREPROC_REQUIRED {
    if {[catch {set _fd [open $_f r]} _err]} {
        set _precisa_preprocessar 1; break
    }
    close $_fd
}
if {$_precisa_preprocessar} {
    if {![file exists $_PYHP_SCRIPT]} {
        error "pyhp.py nao encontrado em: $_PYHP_SCRIPT"
    }
    set _old_ph ""; set _old_pp ""
    if {[info exists ::env(PYTHONHOME)]} { set _old_ph $::env(PYTHONHOME); unset ::env(PYTHONHOME) }
    if {[info exists ::env(PYTHONPATH)]} { set _old_pp $::env(PYTHONPATH); unset ::env(PYTHONPATH) }
    if {$PYTHON_EXE eq ""} { error "PYTHON_EXE nao definido em config.tcl" }
    run_all_preprocessing $PYTHON_EXE $_PYHP_SCRIPT $DV_ROOT $NUM_TILES $X_TILES $Y_TILES
    if {$_old_ph ne ""} { set ::env(PYTHONHOME) $_old_ph }
    if {$_old_pp ne ""} { set ::env(PYTHONPATH) $_old_pp }
} else {
    puts "INFO: Arquivos PyHP ja existem — pulando preprocessing."
}
unset -nocomplain _PYHP_SCRIPT _PREPROC_REQUIRED _precisa_preprocessar _f _fd _err

# ========================== FUNCTIONS =======================
proc check_tools {} {
    puts "Verificando ferramentas Xilinx..."
    foreach tool {xvlog xelab xsim} {
        if {[catch {exec cmd /c where $tool} result]} {
            puts "  AVISO: $tool nao encontrado no PATH"
        } else {
            puts "  $tool: [string trim [lindex [split $result \n] 0]]"
        }
    }
}

proc prepare_dir {} {
    global RUN_DIR
    file mkdir $RUN_DIR
}

proc parse_uvm_args {} {
    global UVM_ARGS UVM_TEST UVM_VERBOSITY RND_SEED UVM_RUN_BINARY UVM_TIMEOUT
    if {$UVM_TEST ne ""} {
        lappend UVM_ARGS "-testplusarg" "UVM_TESTNAME=$UVM_TEST"
    }
    if {$UVM_VERBOSITY ne ""} {
        lappend UVM_ARGS "-testplusarg" "UVM_VERBOSITY=$UVM_VERBOSITY"
    }
    if {[info exists UVM_RUN_BINARY] && $UVM_RUN_BINARY ne ""} {
        lappend UVM_ARGS "-testplusarg" "TEST_BINARY=$UVM_RUN_BINARY"
    }
    if {[info exists UVM_TIMEOUT] && $UVM_TIMEOUT ne ""} {
        lappend UVM_ARGS "-testplusarg" "TIMEOUT=$UVM_TIMEOUT"
    }
    if {$RND_SEED ne ""} {
        lappend UVM_ARGS "-testplusarg" "seed=$RND_SEED"
    }
}

proc compile {} {
    global RUN_DIR ROOT_DIR RTL_PATHS TB_PATHS
    global XVLOG_RTL_FILES XVLOG_TB_FILES
    global ALL_VERILOG_DEFINES

    puts "Compilando V2... $::CUR_DATE"
    prepare_dir
    cd $RUN_DIR

    set inc_flags [list "--include" $ROOT_DIR]
    foreach d $RTL_PATHS { lappend inc_flags "--include" $d }
    foreach d $TB_PATHS  { lappend inc_flags "--include" $d }

    set def_flags {}
    foreach d $ALL_VERILOG_DEFINES {
        if {$d ne ""} { lappend def_flags "--define" $d }
    }

    set flist_path [file join $RUN_DIR "xvlog_sources.f"]
    set fd [open $flist_path w]
    fconfigure $fd -encoding utf-8 -translation lf
    foreach f [concat $XVLOG_RTL_FILES $XVLOG_TB_FILES] {
        puts $fd [file nativename $f]
    }
    close $fd

    puts "INFO: xvlog: [llength $XVLOG_RTL_FILES] RTL + [llength $XVLOG_TB_FILES] UVM files"
    if {[catch {
        exec xvlog --sv --relax \
            {*}$inc_flags \
            {*}$def_flags \
            -f $flist_path \
            -L uvm \
            --log xvlog_compile.log >@stdout 2>@stderr
    } err]} {
        puts "ERROR in xvlog: $err"
        error $err
    }
    puts "INFO: Compile OK. Log: $RUN_DIR/xvlog_compile.log"
}

proc elaborate {} {
    global RUN_DIR TOP_NAME
    puts "Elaborando V2..."
    cd $RUN_DIR
    if {[catch {
        exec xelab $TOP_NAME \
            --relax \
            -s "work.$TOP_NAME" \
            -L uvm \
            -L work \
            --debug all \
            --timescale 1ns/1ps \
            --log elaborate.log >@stdout 2>@stderr
    } err]} {
        puts "ERROR in xelab: $err"
        error $err
    }
    puts "INFO: Elaborate OK. Log: $RUN_DIR/elaborate.log"
}

proc run {GUI_MODE} {
    global RUN_DIR TOP_NAME UVM_ARGS ROOT_DIR
    puts "Rodando simulação V2..."
    cd $RUN_DIR

    if {[info exists ::UVM_RUN_BINARY] && $::UVM_RUN_BINARY ne "" &&
        [file exists $::UVM_RUN_BINARY]} {
        file copy -force $::UVM_RUN_BINARY [file join $RUN_DIR boot.hex]
        puts "INFO: boot.hex <- $::UVM_RUN_BINARY"
    }

    if {$GUI_MODE eq "gui"} {
        exec xsim "work.$TOP_NAME" \
            -wdb "work.$TOP_NAME.wdb" \
            -log simulate.log \
            {*}$UVM_ARGS \
            -gui >@stdout 2>@stderr
    } else {
        if {[catch {
            exec xsim "work.$TOP_NAME" \
                -runall \
                -log simulate.log \
                {*}$UVM_ARGS >@stdout 2>@stderr
        } err]} {
            puts "INFO: xsim exited: $err"
        }
    }
    puts "INFO: Simulation log: $RUN_DIR/simulate.log"
    cd $ROOT_DIR
}

proc clean {} {
    global RUN_DIR
    puts "Limpando $RUN_DIR ..."
    file delete -force $RUN_DIR
}

proc help {} {
    puts ""
    puts "Testbench V2 de Coerência — OpenPiton+CVA6"
    puts ""
    puts "Uso:"
    puts "  vivado -mode batch -source run.tcl -tclargs all"
    puts "  vivado -mode batch -source run.tcl -tclargs compile"
    puts "  vivado -mode batch -source run.tcl -tclargs elaborate"
    puts "  vivado -mode batch -source run.tcl -tclargs run"
    puts "  vivado -mode batch -source run.tcl -tclargs clean"
    puts ""
    puts "Variáveis opcionais:"
    puts "  set UVM_TEST_OVERRIDE    uvmt_opc_coh2_test_c"
    puts "  set UVM_RUN_BINARY_OVERRIDE C:/path/boot_v2.hex"
    puts ""
}

# ========================== FLOW CONTROL ====================
if {![info exists SCRIPT_TARGET]} {
    if {[info exists ::argv] && [llength $::argv] > 0} {
        set SCRIPT_TARGET [lindex $::argv 0]
    } else {
        set SCRIPT_TARGET "help"
    }
}

if {![info exists GUI_MODE]} { set GUI_MODE "no-gui" }

parse_uvm_args

switch $SCRIPT_TARGET {
    compile   { check_tools; compile }
    elaborate { elaborate }
    run       { run $GUI_MODE }
    clean     { clean }
    all       { check_tools; compile; elaborate; run $GUI_MODE }
    default   { help }
}
