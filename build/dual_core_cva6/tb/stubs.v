// stubs.v — módulos comportamentais para simulação

// clk_mmcm_chip: geração de clock MMCM para FPGA standalone
// Instanciado em chip.v:631 dentro de `ifdef PITON_FPGA_CLKS_GEN.
// xelab resolve módulos antes de avaliar `ifdef, então o stub é necessário.
module clk_mmcm_chip (
    input  wire clk_in1_p,
    input  wire clk_in1_n,
    input  wire reset,
    output wire locked,
    output wire core_ref_clk
);
    assign locked       = 1'b1;
    assign core_ref_clk = clk_in1_p;
endmodule

// pll_top: PLL instanciado incondicionalmente em chip.v:778
module pll_top (
    output wire        clk_locked,
    output wire        clk_out,
    input  wire [4:0]  rangeA,
    input  wire        bypass_en,
    input  wire        ref_clk,
    input  wire        rst
);
    assign clk_locked = 1'b1;
    assign clk_out    = ref_clk;
endmodule
