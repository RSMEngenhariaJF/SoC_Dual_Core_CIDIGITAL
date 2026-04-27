#!/bin/bash
# Simula o testbench dual-core CVA6 com Verilator
# Instalar no WSL2: sudo apt install verilator
#
# Uso:  bash run_verilator.sh

set -e
cd "$(dirname "$0")"

PITON_ROOT="$(realpath ../../..)"
BUILD="$PITON_ROOT/build/dual_core_cva6"
DESIGN="$PITON_ROOT/piton/design"
ARIANE="$DESIGN/chip/tile/ariane"

DEFINES=(
    +define+PITON_ARIANE
    +define+PITON_NUM_TILES=2
    +define+PITON_X_TILES=2
    +define+PITON_Y_TILES=1
    +define+PITON_CHIP_FPGA
    +define+SYNTH_STUB
)

echo "==> Gerando C++ com Verilator..."
verilator --cc --exe --build --trace \
    "${DEFINES[@]}" \
    +incdir+"$BUILD/include" \
    +incdir+"$DESIGN/include" \
    +incdir+"$ARIANE/common/local/util" \
    +incdir+"$ARIANE/common/submodules/common_cells/include" \
    --top-module tb_dual_core_cva6 \
    -f filelist.f \
    tb_dual_core_cva6.v \
    --Mdir obj_dir \
    2>&1 | tee verilate.log

echo "==> Executando simulação..."
./obj_dir/Vtb_dual_core_cva6 2>&1 | tee sim.log

echo ""
echo "==> VCD: tb_dual_core_cva6.vcd"
echo "    Visualizar: gtkwave tb_dual_core_cva6.vcd"
