# patch_all_xsim_guards.tcl — recompila todos os arquivos com guards ifndef XSIM
# adicionados nesta sessão: store_buffer, dcache*, scoreboard, load_unit,
# issue_read_operands, instr_queue, frontend, axi_shim, std_nbdcache,
# cache_ctrl, tag_cmp
source [file normalize [file dirname [info script]]/config.tcl]

file mkdir $RUN_DIR
cd $RUN_DIR

set FILES [list \
    "$ARIANE/core/store_buffer.sv"                          \
    "$ARIANE/core/cache_subsystem/wt_l15_adapter.sv"        \
    "$ARIANE/core/cache_subsystem/wt_dcache_mem.sv"         \
    "$ARIANE/core/cache_subsystem/wt_dcache_ctrl.sv"        \
    "$ARIANE/core/cache_subsystem/wt_dcache_missunit.sv"    \
    "$ARIANE/core/cache_subsystem/wt_dcache.sv"             \
    "$ARIANE/core/scoreboard.sv"                            \
    "$ARIANE/core/load_unit.sv"                             \
    "$ARIANE/core/issue_read_operands.sv"                   \
    "$ARIANE/core/frontend/instr_queue.sv"                  \
    "$ARIANE/core/frontend/frontend.sv"                     \
    "$ARIANE/core/axi_shim.sv"                              \
]

foreach f $FILES {
    set fname [file tail $f]
    puts "\n=== PATCH COMPILE: $fname ==="
    exec xvlog -sv \
        --include $ROOT_DIR \
        --include $RTL_PATHS \
        --include $TB_PATHS \
        {*}$XVLOG_INC_DIRS \
        {*}$XVLOG_DEFINES \
        $f \
        -log "xvlog_patch_[string map {.sv {}} $fname].log" >@stdout 2>@stderr
}

puts "\n=== ELABORATE ==="
exec xelab $TOP_NAME \
    -relax \
    -s "work.$TOP_NAME" \
    -L work \
    -timescale 1ns/100ps \
    -log elaborate.log >@stdout 2>@stderr

puts "\n=== ELABORATE OK ==="
