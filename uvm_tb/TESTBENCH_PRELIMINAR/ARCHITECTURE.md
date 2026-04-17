# Arquitetura do Testbench Preliminar

## Estrutura do Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                    tb_preliminary (Top)                         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                     Geradores                           │  │
│  │  • clk (100 MHz)                                        │  │
│  │  • rtc_clk (1 MHz)                                      │  │
│  │  • reset (inicialização)                               │  │
│  └─────────────────────────────────────────────────────────┘  │
│               ↓                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                   soc_top (DUT)                         │  │
│  │                                                         │  │
│  │  ┌─────────────────┐         ┌─────────────────────┐ │  │
│  │  │  Core 0 (CVA6)  │         │  Core 1 (CVA6)      │ │  │
│  │  │  RISC-V 64 bit  │         │  RISC-V 64 bit      │ │  │
│  │  │  L1 D/I Cache   │         │  L1 D/I Cache       │ │  │
│  │  └────────┬────────┘         └────────┬────────────┘ │  │
│  │           │                           │              │  │
│  │           └──────────┬────────────────┘              │  │
│  │                      ↓                                │  │
│  │  ┌───────────────────────────────┐                  │  │
│  │  │  Cache Coherency Unit (CCU)   │                  │  │
│  │  │  • MOESI Protocol             │                  │  │
│  │  │  • Snooping Broadcast         │                  │  │
│  │  └────────────┬────────────────┬─┘                  │  │
│  │               │                │                     │  │
│  │               ↓                ↓                     │  │
│  │  ┌────────────────┐  ┌────────────────┐            │  │
│  │  │   LLC (4KB)    │  │    Arbiter     │            │  │
│  │  │  4-way Set     │  │   (AXI4)       │            │  │
│  │  │  Associative   │  └────────────────┘            │  │
│  │  └────┬───────────┘                                │  │
│  │       │                                             │  │
│  │       └──────────────┬──────────────┐              │  │
│  │                      ↓              ↓               │  │
│  │      ┌──────────────────────────────────┐          │  │
│  │      │     External Memory (32 GB)      │          │  │
│  │      └──────────────────────────────────┘          │  │
│  └─────────────────────────────────────────────────────┘  │
│                      ↑                                      │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Monitores & Verificadores              │  │
│  │  • Memory monitor (0x80000000-0x800001FC)          │  │
│  │  • ACE transaction counter                          │  │
│  │  • MOESI state tracker                              │  │
│  │  • Execution timing tracker                         │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │            Analisadores de Resultado                │  │
│  │  • Verifica Core 0: 0x80000000 (100 valores)       │  │
│  │  • Verifica Core 1: 0x80000100 (100 valores)       │  │
│  │  • Conta transações ACE                             │  │
│  │  • Imprime estatísticas MOESI                       │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Fluxo de Execução

```
┌──────────────┐
│   Início     │
└──────┬───────┘
       ↓
┌──────────────────────────────────┐
│  1. Inicialização (0-10 ciclos)  │
│     • Reset = 1                  │
│     • rtc_clk ciclo único        │
└──────┬───────────────────────────┘
       ↓
┌───────────────────────────────────┐
│  2. Carregamento do Programa      │
│     (10-50 ciclos)                │
│     • Load program.hex em memória │
│     • Core 0: 0x80000000         │
│     • Core 1: 0x80000100         │
└──────┬────────────────────────────┘
       ↓
┌────────────────────────────────────┐
│  3. Execução Dual-Core            │
│     (50-10,000 ciclos)            │
│     • Core 0: loop 100x           │
│     • Core 1: loop 100x           │
│     • Monitorar coerência         │
│     • Contar transações ACE       │
└──────┬─────────────────────────────┘
       ↓
┌────────────────────────────────────┐
│  4. Verificação de Memória        │
│     (10,000 ciclos)               │
│     • Ler 0x80000000-0x800001FC   │
│     • Ler 0x80000100-0x800002FC   │
│     • Comparar com esperado       │
└──────┬─────────────────────────────┘
       ↓
┌────────────────────────────────────┐
│  5. Geração de Relatório          │
│     • Estatísticas MOESI          │
│     • Contagem de ACE trans.      │
│     • Pass/Fail                   │
│     • RESULTADO_TESTE.md          │
└──────┬─────────────────────────────┘
       ↓
┌──────────────┐
│   Término    │
└──────────────┘
```

## Regiões de Memória

```
┌─────────────────────────────────────────┐
│      Espaço de Endereçamento (64-bit)   │
├─────────────────────────────────────────┤
│                                         │
│         Memória Não Utilizada          │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  0x80002000 - 0xFFFFFFFF                │
│  Memória Não Testada                   │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  0x80000300 - 0x80001FFF                │
│  Espaço Livre (1,984 bytes)             │
│                                         │
├──────────────────────────────- ────────┤
│                                         │
│  0x80000100 - 0x800002FC                │
│  CORE 1 RESULTADOS (508 bytes)         │
│  • Valor 0: 0x1                        │
│  • Valor 1: 0x2                        │
│  • ...                                 │
│  • Valor 99: 0x64                      │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  0x80000000 - 0x800000FC                │
│  CORE 0 RESULTADOS (256 bytes)         │
│  • Valor 0: 0x1                        │
│  • Valor 1: 0x2                        │
│  • ...                                 │
│  • Valor 99: 0x64                      │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  0x00000000 - 0x7FFFFFFF                │
│  Espaço Livre (2 GB)                   │
│                                         │
└─────────────────────────────────────────┘
```

## Sequência de Protocolo ACE

```
Ciclo 0-10: Reset & Inicialização
   ┌─────────────────┐
   │    reset = 1    │
   │  rtc_toggle = 1 │
   └─────────────────┘

Ciclo 11-50: Carregamento de Programa
   ┌──────────────────────────────────┐
   │  memory[0x80000000] = Core0_prog │
   │  memory[0x80000100] = Core1_prog │
   └──────────────────────────────────┘

Ciclo 51-10000: Execução com Coerência
   ┌─────────────────────────────────────────┐
   │ Core0 Write → CCU (MOESI: M=Modified)   │
   │ Core1 Snoop → CCU (Invalida L1)        │
   │ Core1 Write → CCU (MOESI: M=Modified)  │
   │ ...                                    │
   └─────────────────────────────────────────┘

Ciclo 10001-10100: Verificação
   ┌────────────────────────────────┐
   │ Ler memory[0x80000000-0x0FC]   │
   │ Ler memory[0x80000100-0x2FC]   │
   │ Verificar valores              │
   │ Comparar com esperado          │
   └────────────────────────────────┘
```

## Monitoramento em Tempo Real

### Contadores Mantidos

```
┌─────────────────────────────────────────┐
│   Counters & Monitores durante Execução  │
├─────────────────────────────────────────┤
│                                         │
│  cycle_count          : [0, 10000+]    │
│  ace_read_count       : [0, N]         │
│  ace_write_count      : [0, N]         │
│  ace_snoop_count      : [0, N]         │
│  core0_instr_count    : [0, 100+]      │
│  core1_instr_count    : [0, 100+]      │
│  moesi_modified_count : [0, N]         │
│  moesi_owned_count    : [0, N]         │
│  moesi_exclusive_count: [0, N]         │
│  moesi_shared_count   : [0, N]         │
│  moesi_invalid_count  : [0, N]         │
│                                         │
└─────────────────────────────────────────┘
```

### Checklist de Verificação

```
┌──────────────────────────────────────────┐
│  Diagnósticos do Teste                   │
├──────────────────────────────────────────┤
│                                          │
│  ✓ Clock e Reset funcionando             │
│  ✓ Program.hex carregado corretamente   │
│  ✓ Core 0 executando instruções         │
│  ✓ Core 1 executando instruções         │
│  ✓ Transações ACE detectadas            │
│  ✓ Estados MOESI transitando             │
│  ✓ Coerência de cache mantida           │
│  ✓ Memory writes completados            │
│  ✓ Valores em 0x80000000+ corretos      │
│  ✓ Valores em 0x80000100+ corretos      │
│                                          │
└──────────────────────────────────────────┘
```

## Estrutura de Diretórios

```
uvm_tb/TESTBENCH_PRELIMINAR/
│
├── program.hex              # RISC-V bytecode dual-core
│
├── tb_preliminary.sv        # Testbench SystemVerilog (625 linhas)
│
├── run_preliminary_test.py  # Automação em Python
│
├── Makefile                 # Targets: preliminar, compile, simulate, clean
│
├── README.md                # Documentação completa
│
├── ARCHITECTURE.md          # Este arquivo (arquitetura visual)
│
└── work/                    # Diretório gerado (compilação)
    ├── sim/
    │   ├── tb_preliminary.vvp      # Simulação compilada
    │   ├── tb_preliminary.vcd      # Dump de sinais
    │   ├── simulation.log           # Log de saída
    │   └── RESULTADO_TESTE.md       # Relatório final
    └── xsim/               # (alternativo Vivado)
```

## Saída Esperada do Teste

```
╔════════════════════════════════════════════════════════════════╗
║  TESTBENCH PRELIMINAR - TESTE CVA6 DUAL-CORE                  ║
║  Data/Hora: [timestamp]                                        ║
╠════════════════════════════════════════════════════════════════╣

[LOAD] Carregando programa em memória...
  ✓ Program.hex loaded (512 bytes)
  ✓ Core 0 entry point: 0x80000000
  ✓ Core 1 entry point: 0x80000100

[EXEC] Iniciando execução...
  Ciclo 0000: reset_n=1, rtc=1
  Ciclo 0050: Core 0 começando loops
  Ciclo 0100: Core 1 começando loops
  Ciclo 0200: ACE transactions: 42, MOESI states: M=12, E=5, S=3, I=22
  ...
  Ciclo 10000: Execução completa

[VERIFY] Verificando valores em memória...
  Core 0 (0x80000000):
    ✓ memory[0x80000000] = 0x00000001
    ✓ memory[0x80000004] = 0x00000002
    ...
    ✓ memory[0x800001FC] = 0x00000064 (100 verificado)

  Core 1 (0x80000100):
    ✓ memory[0x80000100] = 0x00000001
    ✓ memory[0x80000104] = 0x00000002
    ...
    ✓ memory[0x800002FC] = 0x00000064 (100 verificado)

[STATS] Estatísticas:
  Total Cycles:       10050
  ACE Reads:         8,432
  ACE Writes:        4,216
  Snoops:             2,108
  MOESI Transitions: 12,344
  Pass: ✅ TODOS OS TESTES PASSARAM

╚════════════════════════════════════════════════════════════════╝

RESULTADO_TESTE.md gerado com sucesso!
```

## Próximas Etapas

1. **Executar o teste**:
   ```bash
   make preliminar
   ```
   ou
   ```bash
   python3 run_preliminary_test.py
   ```

2. **Visualizar resultados**:
   - Arquivo: `work/sim/RESULTADO_TESTE.md`
   - VCD: `work/sim/tb_preliminary.vcd`

3. **Analisar com GTKWave** (opcional):
   ```bash
   make wave
   ```

4. **Proceder para UVM**:
   - Se PASS: Continue com testes UVM completos
   - Se FAIL: Debug com logs e VCD

---

**Criado em**: 16-04-2026  
**Status**: ✅ Pronto para Execução  
**Next Phase**: Phase 3 - Compilação e Simulação
