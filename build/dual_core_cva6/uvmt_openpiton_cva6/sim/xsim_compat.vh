// ============================================================================
// xsim_compat.vh
// Cabecalho de compatibilidade para rodar o RTL do OpenPiton no Vivado XSim.
//
// Define macros que resolvem incompatibilidades entre as construcoes
// Verilog/SystemVerilog usadas no OpenPiton e o compilador xvlog do XSim.
// Adicionado como global include header no projeto Vivado (sim_1 fileset).
// ============================================================================

`ifndef XSIM_COMPAT_VH
`define XSIM_COMPAT_VH

// ---------------------------------------------------------------------------
// Remocao de construcoes nao suportadas pelo XSim
// ---------------------------------------------------------------------------

// XSim nao suporta $bitstoreal / $realtobits em alguns contextos
// `define XSIM_NO_REAL_CONV

// Desabilita geracoes de PLI ($dumpfile, $dumpvars) que nao se aplicam no XSim
// O XSim usa sua propria infra de waveform (WDB)
`define NO_PLI_DUMP

// ---------------------------------------------------------------------------
// Marcadores de ambiente XSim (ja definido em ALL_VERILOG_DEFINES, aqui
// como fallback para arquivos que nao recebem defines via linha de comando)
// ---------------------------------------------------------------------------
`ifndef XSIM
  `define XSIM
`endif

// ---------------------------------------------------------------------------
// Defines comuns do OpenPiton que o XSim pode precisar ver via include
// (o principal canal sao os ALL_VERILOG_DEFINES do config.tcl,
//  mas este fallback garante compilacao mesmo sem eles)
// ---------------------------------------------------------------------------
`ifndef NO_SCAN
  `define NO_SCAN
`endif

`endif // XSIM_COMPAT_VH
