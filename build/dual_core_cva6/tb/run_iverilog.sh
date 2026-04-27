#!/bin/bash
# Simula o testbench dual-core CVA6 com Icarus Verilog (iverilog)
# Instalar no WSL2: sudo apt install iverilog
#
# Uso:  bash run_iverilog.sh

set -e
cd "$(dirname "$0")"

PITON_ROOT="$(realpath ../../..)"
BUILD="$PITON_ROOT/build/dual_core_cva6"
DESIGN="$PITON_ROOT/piton/design"
ARIANE="$DESIGN/chip/tile/ariane"

DEFINES=(
    -DPITON_ARIANE
    -DPITON_NUM_TILES=2
    -DPITON_X_TILES=2
    -DPITON_Y_TILES=1
    -DPITON_CHIP_FPGA
    -DSYNTH_STUB
)

INCDIRS=(
    -I"$BUILD/include"
    -I"$DESIGN/include"
    -I"$ARIANE/common/local/util"
    -I"$ARIANE/common/submodules/common_cells/include"
)

# Coleta fontes SystemVerilog do CVA6
CVA6_SV=$(find "$ARIANE/core" "$ARIANE/common" \
    -name "*.sv" -not -path "*/tb/*" -not -path "*/example_tb/*" 2>/dev/null | tr '\n' ' ')

echo "==> Compilando design dual-core CVA6..."
iverilog -g2012 \
    "${DEFINES[@]}" \
    "${INCDIRS[@]}" \
    -s tb_dual_core_cva6 \
    tb_dual_core_cva6.v \
    stubs.v \
    "$BUILD/rtl/chip/tile/rtl/tile.v" \
    "$BUILD/rtl/chip/tile/rtl/config_regs.v" \
    "$BUILD/rtl/chip/tile/common/rtl/flat_id_to_xy.v" \
    "$BUILD/rtl/chip/tile/common/rtl/xy_to_flat_id.v" \
    "$BUILD/rtl/chip/tile/dmbr/rtl/dmbr.v" \
    "$BUILD/rtl/chip/tile/dynamic_node/rtl/"*.v \
    "$BUILD/rtl/chip/tile/dynamic_node/components/rtl/"*.v \
    "$BUILD/rtl/chip/tile/dynamic_node/dynamic/rtl/"*.v \
    "$BUILD/rtl/chip/tile/l15/rtl/"*.v \
    "$BUILD/rtl/chip/tile/l15/rtl/sram_wrappers/"*.v \
    "$BUILD/rtl/chip/tile/l2/rtl/"*.v \
    "$BUILD/rtl/chip/tile/l2/rtl/sram_wrappers/"*.v \
    "$BUILD/rtl/common/rtl/"*.v \
    "$DESIGN/common/rtl/"*.v \
    "$DESIGN/chip/tile/rtl/ccx_l15_transducer.v" \
    $CVA6_SV \
    -o sim_dual_core_cva6 \
    2>&1 | tee compile.log

echo "==> Compilação concluída. Iniciando simulação..."
./sim_dual_core_cva6 2>&1 | tee sim.log

echo ""
echo "==> VCD gerado: tb_dual_core_cva6.vcd"
echo "    Visualizar: gtkwave tb_dual_core_cva6.vcd"
