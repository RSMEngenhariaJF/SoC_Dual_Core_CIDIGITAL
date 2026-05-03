# patch_dcache_asserts.tcl — adiciona ifndef XSIM a assertions dos módulos dcache
# Recompila: wt_l15_adapter, wt_dcache_mem, wt_dcache_ctrl, wt_dcache, wt_dcache_missunit
source [file normalize [file dirname [info script]]/config.tcl]

file mkdir $RUN_DIR
cd $RUN_DIR

set FILES [list \
    "$ARIANE/core/cache_subsystem/wt_l15_adapter.sv"    \
    "$ARIANE/core/cache_subsystem/wt_dcache_mem.sv"     \
    "$ARIANE/core/cache_subsystem/wt_dcache_ctrl.sv"    \
    "$ARIANE/core/cache_subsystem/wt_dcache_missunit.sv" \
    "$ARIANE/core/cache_subsystem/wt_dcache.sv"         \
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
