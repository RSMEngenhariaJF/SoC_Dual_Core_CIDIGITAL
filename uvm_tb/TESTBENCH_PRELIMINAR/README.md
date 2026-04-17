# 🧪 TESTBENCH PRELIMINAR - Teste de Execução Dual-Core CVA6

**Objetivo**: Demonstrar execução paralela de 2 cores RISC-V com análise de coerência ACE

---

## 📋 Conteúdo desta Pasta

```
TESTBENCH_PRELIMINAR/
├── program.hex               # Programa RISC-V em formato HEX
├── tb_preliminary.sv         # Testbench SystemVerilog
├── run_preliminary_test.py   # Script Python para executar teste
├── Makefile                  # Targets de compilação
└── README.md                 # Este arquivo
```

---

## 🎯 Fluxo de Execução

```
┌─────────────────────────────────────────────────────┐
│  1. Load Program (program.hex)                      │
│     ↓                                               │
│  2. Compile Testbench (tb_preliminary.sv)           │
│     ↓                                               │
│  3. Execute Simulation                              │
│     │                                               │
│     ├─ Core 0: Incrementa x5 (0→100)                │
│     ├─ Core 1: Incrementa x6 (0→100)                │
│     └─ Ambos escrevem em memória                    │
│     ↓                                               │
│  4. Monitor ACE Transactions                        │
│     ├─ Read Address                                 │
│     ├─ Write Address                                │
│     ├─ Snoop Requests                               │
│     └─ Coherency Responses                          │
│     ↓                                               │
│  5. Verify Results                                  │
│     ├─ Memoria Core 0 (0x80000000)                  │
│     ├─ Memoria Core 1 (0x80000100)                  │
│     └─ MOESI State Transitions                      │
│     ↓                                               │
│  6. Generate Report (RESULTADO_TESTE.md)            │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Como Executar

### Opção 1: Python (Recomendado)
```bash
cd uvm_tb/TESTBENCH_PRELIMINAR
python run_preliminary_test.py
```

### Opção 2: Make
```bash
make preliminar
# ou
make clean
make compile
make simulate
```

### Opção 3: Manual com iverilog
```bash
cd uvm_tb/TESTBENCH_PRELIMINAR

# Compilar
iverilog -g2012 -o tb_preliminary.vvp tb_preliminary.sv

# Executar
vvp tb_preliminary.vvp
```

### Opção 4: Manual com Vivado
```bash
cd uvm_tb/TESTBENCH_PRELIMINAR

# Compilar
xvlog -sv -work work tb_preliminary.sv

# Executar
xsim work.tb_preliminary -R
```

---

## 📝 O que o Teste Faz

### Programa Carregado (program.hex)

**Core 0:**
```risc-v
li x5, 0              # Inicializa contador
li x10, 0x80000000    # Endereço de escrita

loop0:
  addi x5, x5, 1      # Incrementa x5
  sw x5, 0(x10)       # Escreve em memória
  addi x10, x10, 4    # Próximo endereço
  bne x5, x6, loop0   # Repete 100 vezes
```

**Core 1:**
```risc-v
li x6, 0              # Inicializa contador
li x11, 0x80000100    # Endereço de escrita

loop1:
  addi x6, x6, 1      # Incrementa x6
  sw x6, 0(x11)       # Escreve em memória
  addi x11, x11, 4    # Próximo endereço
  bne x6, x7, loop1   # Repete 100 vezes
```

### Análise Esperada

**Core 0 Writes:**
```
0x80000000: 0x00000001
0x80000004: 0x00000002
0x80000008: 0x00000003
...
0x800001FC: 0x00000064 (100)
```

**Core 1 Writes:**
```
0x80000100: 0x00000001
0x80000104: 0x00000002
0x80000108: 0x00000003
...
0x800002FC: 0x00000064 (100)
```

### Transações ACE Monitoradas

| Tipo | Quantidade | Descrição |
|------|-----------|-----------|
| Read Address | ~500 | Leituras de instrução + dados |
| Write Address | ~500 | Escritas de dados |
| Write Data | ~500 | Dados sendo escritos |
| Write Response | ~500 | Confirmação de escrita |
| Snoop | ~50 | Requisições de snooping |
| Coherency Response | ~50 | Respostas de coerência |

### Verificação MOESI

```
States Detectados:
  ✓ Modified (M)   - Cache tem dado modificado
  ✓ Shared (S)     - Dados compartilhados entre caches
  ✓ Invalid (I)    - Linha de cache inválida

Transições Esperadas:
  ✓ I → M          (Leitura/escrita exclusiva)
  ✓ M → S          (Snoop hit, core escreve)
  ✓ S → I          (Outro core escreve)
  ✓ M → I          (Eviction)
```

---

## 📊 Saída Esperada

```
╔═══════════════════════════════════════════════════════════╗
║  TESTBENCH PRELIMINAR - CVA6 DUAL-CORE EXECUTION TEST     ║
║  Objetivo: Demonstrar execução de 2 cores com coerência   ║
╚═══════════════════════════════════════════════════════════╝

[SETUP] Inicializando ambiente de teste...
[SETUP] ✓ Reset finalizado em 100 ns
[LOAD] Carregando programa RISC-V na memória...
[LOAD] ✓ Programa carregado com sucesso

[EXEC] Iniciando execução...
[EXEC] Core 0: Executa loop de incremento x5 (0→100)
[EXEC] Core 1: Executa loop de incremento x6 (0→100)
[EXEC] Ambos cores escrevem resultados em memória

[ACE] Transação ACE #1 detectada em 1000 ns
[MOESI] Evento de coerência #1 em 2000 ns
...

[EXEC] ✓ Execução finalizada em 10000 ciclos

[VERIFY] Verificando resultados...
  ┌─ Core 0 Results (0x80000000):
  │  [0x80000000] = 0x00000001 ✓
  │  [0x80000004] = 0x00000002 ✓
  │  [0x80000008] = 0x00000003 ✓
  ...
  └─ Core 1 Results (0x80000100):
     [0x80000100] = 0x00000001 ✓
     [0x80000104] = 0x00000002 ✓
     [0x80000108] = 0x00000003 ✓

[ANALYSIS] Análise de Coerência ACE:
  - Transações ACE: 1000
  - Eventos de coerência: 50
  - Escritas Core 0: 100
  - Escritas Core 1: 100

[RESULT] ✅ TESTE PRELIMINAR CONCLUÍDO COM SUCESSO!
         Ambos os cores executaram em paralelo com coerência mantida.
```

---

## 📈 Relatório Gerado

Após execução, o teste gera: **RESULTADO_TESTE.md**

Conteúdo:
- ✅ Status geral do teste
- ✅ Resumo de execução
- ✅ Resultados de cada core
- ✅ Análise de transações ACE
- ✅ Verificação de estado MOESI
- ✅ Conteúdo de memória verificado
- ✅ Conclusões

---

## 🔧 Requisitos

### Obrigatório
- [ ] SystemVerilog compiler (iverilog, VCS, ou Vivado)
- [ ] Python 3.6+ (para run_preliminary_test.py)

### Opcional
- [ ] Vivado (para simulação gráfica)
- [ ] GTKWave (para visualização de waveforms)

---

## 🐛 Troubleshooting

### Erro: "iverilog: command not found"
**Solução**: Instale iverilog
```bash
# Ubuntu/Debian
sudo apt-get install iverilog

# macOS
brew install iverilog

# Windows (MinGW)
# Download from http://iverilog.icarus.com/
```

### Erro: "tb_preliminary.vvp: Permission denied"
**Solução**: 
```bash
chmod +x tb_preliminary.vvp
vvp tb_preliminary.vvp
```

### Erro: Testbench não compila
**Verificar**:
1. ✓ Arquivo tb_preliminary.sv existe?
2. ✓ Sintaxe SystemVerilog correta?
3. ✓ Caminhos relativos corretos?

---

## 📝 Próximos Passos

Após este teste preliminar passar:

1. **UVM Framework Completo** 
   - Executar `uvm_tests.sv`
   - Todos 6 test cases

2. **Stress Testing**
   - 1000+ transações paralelas
   - Múltiplos padrões de acesso

3. **Performance Analysis**
   - Latência ACE
   - Throughput
   - Coverage

4. **FPGA Synthesis** (Opcional)
   - Vivado build
   - Place & Route
   - Timing analysis

---

## 📞 Suporte

Se tem problemas:
1. Verifique que o programa.hex é válido
2. Verifique que tb_preliminary.sv compila
3. Procure por mensagens de erro específicas
4. Consulte a documentação do simulador

---

**Teste Preliminar - Versão 1.0**  
**Data**: 16/04/2026  
**Status**: ✅ Pronto para uso
