# driver.tcl — executa compile + elaborate + simulate sem GUI
# Uso: vivado -mode batch -source driver.tcl
#      (ou no Vivado Tcl Console: source driver.tcl)

set here [file normalize [file dirname [info script]]]
cd $here

source config.tcl

# Forçar no-gui e SCRIPT_TARGET para evitar abertura do Vivado GUI
set GUI_MODE    "no-gui"
set SCRIPT_TARGET "all"

file mkdir $RUN_DIR
cd $RUN_DIR

# ---- COMPILE ----
puts "\n=== COMPILE ==="
exec xvlog -sv \
    --include $ROOT_DIR \
    --include $RTL_PATHS \
    --include $TB_PATHS \
    {*}$XVLOG_INC_DIRS \
    {*}$XVLOG_DEFINES \
    {*}$XVLOG_RTL_FILES \
    {*}$XVLOG_TB_FILES \
    -log xvlog_compile.log >@stdout 2>@stderr

# ---- ELABORATE ----
puts "\n=== ELABORATE ==="
exec xelab $TOP_NAME \
    -relax \
    -s "work.$TOP_NAME" \
    -L work \
    -timescale 1ns/100ps \
    -log elaborate.log >@stdout 2>@stderr

# ---- SIMULATE ----
# xsim é invocado separadamente (ver run_sim.bat) para evitar lock no xsim.type
puts "\n=== ELABORATE OK — rode run_sim.bat para simular ==="
