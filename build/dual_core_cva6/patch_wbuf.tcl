# patch_wbuf.tcl — recompila wt_dcache_wbuffer.sv (sem assertions em xsim) e re-elabora
source [file normalize [file dirname [info script]]/config.tcl]

set WBUF_FILE [file normalize "$PITON_DIR/piton/design/chip/tile/ariane/core/cache_subsystem/wt_dcache_wbuffer.sv"]

file mkdir $RUN_DIR
cd $RUN_DIR

puts "\n=== PATCH COMPILE: wt_dcache_wbuffer ==="
exec xvlog -sv \
    --include $ROOT_DIR \
    --include $RTL_PATHS \
    --include $TB_PATHS \
    {*}$XVLOG_INC_DIRS \
    {*}$XVLOG_DEFINES \
    $WBUF_FILE \
    -log xvlog_patch.log >@stdout 2>@stderr

puts "\n=== ELABORATE ==="
exec xelab $TOP_NAME \
    -relax \
    -s "work.$TOP_NAME" \
    -L work \
    -timescale 1ns/100ps \
    -log elaborate.log >@stdout 2>@stderr

puts "\n=== ELABORATE OK ==="
