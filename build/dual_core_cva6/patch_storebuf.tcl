# patch_storebuf.tcl — recompila store_buffer.sv (xsim guards) e re-elabora
source [file normalize [file dirname [info script]]/config.tcl]

set FILE [file normalize "$ARIANE/core/store_buffer.sv"]

file mkdir $RUN_DIR
cd $RUN_DIR

puts "\n=== PATCH COMPILE: store_buffer ==="
exec xvlog -sv \
    --include $ROOT_DIR \
    --include $RTL_PATHS \
    --include $TB_PATHS \
    {*}$XVLOG_INC_DIRS \
    {*}$XVLOG_DEFINES \
    $FILE \
    -log xvlog_patch_storebuf.log >@stdout 2>@stderr

puts "\n=== ELABORATE ==="
exec xelab $TOP_NAME \
    -relax \
    -s "work.$TOP_NAME" \
    -L work \
    -timescale 1ns/100ps \
    -log elaborate.log >@stdout 2>@stderr

puts "\n=== ELABORATE OK ==="
