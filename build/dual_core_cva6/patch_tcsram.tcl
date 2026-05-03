# patch_tcsram.tcl — recompila tc_sram.sv (com $isunknown guards) e re-elabora
source [file normalize [file dirname [info script]]/config.tcl]

set TCSRAM_FILE [file normalize "$ARIANE/corev_apu/src/tech_cells_generic/src/rtl/tc_sram.sv"]

file mkdir $RUN_DIR
cd $RUN_DIR

puts "\n=== PATCH COMPILE: tc_sram ==="
exec xvlog -sv \
    --include $ROOT_DIR \
    --include $RTL_PATHS \
    --include $TB_PATHS \
    {*}$XVLOG_INC_DIRS \
    {*}$XVLOG_DEFINES \
    $TCSRAM_FILE \
    -log xvlog_patch_tcsram.log >@stdout 2>@stderr

puts "\n=== ELABORATE ==="
exec xelab $TOP_NAME \
    -relax \
    -s "work.$TOP_NAME" \
    -L work \
    -timescale 1ns/100ps \
    -log elaborate.log >@stdout 2>@stderr

puts "\n=== ELABORATE OK ==="
