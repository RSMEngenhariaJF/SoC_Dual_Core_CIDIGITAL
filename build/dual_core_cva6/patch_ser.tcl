# patch_ser.tcl — recompila noc_axi4_bridge_ser.v e re-elabora
source [file normalize [file dirname [info script]]/config.tcl]

set SER_FILE [file normalize "$PITON_DIR/piton/design/chipset/noc_axi4_bridge/rtl/noc_axi4_bridge_ser.v"]

file mkdir $RUN_DIR
cd $RUN_DIR

puts "\n=== PATCH COMPILE: noc_axi4_bridge_ser ==="
exec xvlog -sv \
    --include $ROOT_DIR \
    --include $RTL_PATHS \
    --include $TB_PATHS \
    {*}$XVLOG_INC_DIRS \
    {*}$XVLOG_DEFINES \
    $SER_FILE \
    -log xvlog_patch.log >@stdout 2>@stderr

puts "\n=== ELABORATE ==="
exec xelab $TOP_NAME \
    -relax \
    -s "work.$TOP_NAME" \
    -L work \
    -timescale 1ns/100ps \
    -log elaborate.log >@stdout 2>@stderr

puts "\n=== ELABORATE OK ==="
