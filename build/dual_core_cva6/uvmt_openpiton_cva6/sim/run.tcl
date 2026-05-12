# ============================================================
# Vivado Simulator (xsim) script
# Description: This script allows configuration and control of
# the compilation, elaboration and simulation flows with the
# built-in Vivado simulator.
#
# Author: Elivander Judas Tadeu Pereira - Inatel / adapted for
#         OpenPiton+CVA6 UVM Environment (Windows / Vivado XSim)
# Date: 2026-03-20
# Version: 2.0
#
# Version history:
# 1.0 Initial version aiming source code from UVM_PRIMER book.
# 2.0 Adapted for OpenPiton+CVA6 UVM testbench (xvlog/xelab/xsim
#     direct flow, replacing launch_simulation Vivado project API).
#
# Usage:
#   vivado -mode tcl
#   cd <sim_dir_path>
#   set SCRIPT_TARGET  all          ;# compile + elaborate + run
#   source run.tcl
#
# For batch mode (no interactive session):
#   vivado -mode batch -source run.tcl -tclargs all
# ============================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]
source [file join $SCRIPT_DIR config.tcl]


# ========================== INIT ============================
set CUR_DATE [clock format [clock seconds] -format "|%Y/%m/%d %H:%M:%S|"]


# ========================== PREPROCESSING ===================
# Verifica se os headers PyHP já foram gerados; se não, gera.
# Executado uma única vez — reruns encontram os arquivos e pulam.

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
    puts "INFO: Gerado: $out_file"
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
    set h_pyv_dirs [list "$dv_root/design/include" "$dv_root/verif/env/manycore"]
    set h_pyv_total 0
    foreach h_dir $h_pyv_dirs {
        foreach pyv [glob -nocomplain -type f -directory $h_dir "*.h.pyv"] {
            set out [string range $pyv 0 end-4]
            run_pyhp $python_cmd $pyhp_script $pyv $out
            set base [file rootname $out]; set ext [file extension $out]
            set tmp_file "${base}.tmp${ext}"
            file copy -force $out $tmp_file
            incr h_pyv_total
        }
    }
    set total 0
    foreach dir [list "$dv_root/design"] {
        foreach pyv [find_files_recursive $dir "*.v.pyv"] {
            run_pyhp $python_cmd $pyhp_script $pyv [string range $pyv 0 end-4]
            incr total
        }
    }
    puts "INFO: Preprocessing: $total .v.pyv + $h_pyv_total .h.pyv"
}

set _PYHP_SCRIPT [file join $DV_ROOT tools bin pyhp.py]
set _PREPROC_REQUIRED [list \
    [file join $DV_ROOT design include define.h]      \
    [file join $DV_ROOT design include define.tmp.h]  \
    [select_rtl $RTL_PATCHED [file join $DV_ROOT design chip rtl chip.v]] \
    [select_rtl $RTL_PATCHED [file join $DV_ROOT design chip tile rtl tile.v]] \
]

set _precisa_preprocessar 0
foreach _f $_PREPROC_REQUIRED {
    if {[catch {set _fd [open $_f r]} _err]} {
        puts "INFO: Ausente (precisa preprocessing): [file tail $_f]"
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
    set _python_cmd $PYTHON_EXE
    if {$_python_cmd eq ""} { error "PYTHON_EXE nao definido em config.tcl" }
    run_all_preprocessing $_python_cmd $_PYHP_SCRIPT $DV_ROOT $NUM_TILES $X_TILES $Y_TILES
    if {$_old_ph ne ""} { set ::env(PYTHONHOME) $_old_ph }
    if {$_old_pp ne ""} { set ::env(PYTHONPATH) $_old_pp }
} else {
    puts "INFO: Arquivos PyHP ja existem — pulando preprocessing."
}
unset -nocomplain _PYHP_SCRIPT _PREPROC_REQUIRED _precisa_preprocessar _f _fd _err
unset -nocomplain _old_ph _old_pp _python_cmd


# ========================== FUNCTIONS =======================

proc check_tools {} {
    puts "Checking for Xilinx simulation tools..."
    foreach tool {xvlog xelab xsim} {
        if {[catch {exec cmd /c where $tool} result]} {
            puts "  WARNING: $tool not found in PATH (expected inside Vivado session)"
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
    global XVHDL_RTL_FILES XVHDL_TB_FILES
    global XVLOG_RTL_FILES XVLOG_TB_FILES
    global ALL_VERILOG_DEFINES

    puts "Compiling... $::CUR_DATE"
    prepare_dir
    cd $RUN_DIR

    # Build --include flags from RTL_PATHS + TB_PATHS lists
    set inc_flags [list "--include" $ROOT_DIR]
    foreach d $RTL_PATHS { lappend inc_flags "--include" $d }
    foreach d $TB_PATHS  { lappend inc_flags "--include" $d }

    # Build --define flags from ALL_VERILOG_DEFINES list
    set def_flags {}
    foreach d $ALL_VERILOG_DEFINES {
        if {$d ne ""} { lappend def_flags "--define" $d }
    }

    # VHDL compilation (none expected for this project)
    if {[llength $XVHDL_RTL_FILES] > 0 || [llength $XVHDL_TB_FILES] > 0} {
        exec xvhdl --2008 \
            {*}$XVHDL_RTL_FILES \
            {*}$XVHDL_TB_FILES \
            -log xvhdl_compile.log >@stdout 2>@stderr
    }

    # SV/Verilog compilation
    # Escreve filelist para evitar limite de tamanho de linha de comando do Windows
    set flist_path [file join $RUN_DIR "xvlog_sources.f"]
    set fd [open $flist_path w]
    fconfigure $fd -encoding utf-8 -translation lf
    foreach f [concat $XVLOG_RTL_FILES $XVLOG_TB_FILES] {
        puts $fd [file nativename $f]
    }
    close $fd

    puts "INFO: xvlog: [llength $XVLOG_RTL_FILES] RTL + [llength $XVLOG_TB_FILES] UVM files (via filelist)"
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
    puts "INFO: Compile step complete. Log: $RUN_DIR/xvlog_compile.log"
}

proc elaborate {} {
    global RUN_DIR TOP_NAME

    puts "Elaborating..."
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
    puts "INFO: Elaborate step complete. Log: $RUN_DIR/elaborate.log"
}

proc run {GUI_MODE} {
    global RUN_DIR TOP_NAME UVM_ARGS ROOT_DIR

    puts "Running simulation..."
    cd $RUN_DIR

    # Copy boot hex into RUN_DIR so $readmemh("boot.hex", mem) resolves correctly.
    # UVM_RUN_BINARY holds the absolute path set in config.tcl.
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
            -gui \
            -tclbatch "$ROOT_DIR/wave.tcl" >@stdout 2>@stderr
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
    puts "Cleaning $RUN_DIR ..."
    file delete -force $RUN_DIR
}

proc help {} {
    puts ""
    puts "Usage:"
    puts "1. Open Vivado in tcl mode:"
    puts "      vivado -mode tcl"
    puts "2. Change directory to the project folder:"
    puts "      cd <sim_dir_path>"
    puts "3. Set the environment variables as needed:"
    puts "      set UVM_TEST        <uvm_test_name>"
    puts "      set UVM_VERBOSITY   <UVM_LOW|MEDIUM|HIGH>"
    puts "      set UVM_ARGS        <list>"
    puts "      set RND_SEED        <int>"
    puts "      set SCRIPT_TARGET   <target>"
    puts "      set GUI_MODE        <no-gui|gui>"
    puts ""
    puts "Available script targets:"
    puts "      compile             Compile design (xvlog)"
    puts "      elaborate           Elaborate design (xelab)"
    puts "      run                 Run simulation (xsim)"
    puts "      all                 Full flow (compile+elaborate+run)"
    puts "      clean               Clean output directory"
    puts ""
    puts "4. Run the file: source run.tcl"
    puts ""
    puts "For batch mode, pass target via -tclargs:"
    puts "      vivado -mode batch -source run.tcl -tclargs all"
    puts ""
}


# ========================== FLOW CONTROL ====================

# Support -tclargs for batch mode: vivado -mode batch -source run.tcl -tclargs all
if {![info exists SCRIPT_TARGET]} {
    if {[info exists ::argv] && [llength $::argv] > 0} {
        set SCRIPT_TARGET [lindex $::argv 0]
    } else {
        set SCRIPT_TARGET "help"
    }
}

if {![info exists GUI_MODE]} {
    set GUI_MODE "no-gui"
}

parse_uvm_args

switch $SCRIPT_TARGET {
    compile {
        check_tools
        compile
    }
    elaborate {
        elaborate
    }
    run {
        run $GUI_MODE
    }
    clean {
        clean
    }
    all {
        check_tools
        compile
        elaborate
        run $GUI_MODE
    }
    default {
        help
    }
}
