# Guia Rápido: CVA6 Real Pronto para Usar

## ✅ Status Atual

O repositório completo do CVA6 foi trazido para:
```
c:\Users\rafae\Documents\trabalho final\rtl\cores\cva6-master\
```

**Estrutura:**
- `cva6-master/core/` - Núcleo CVA6 (arquivo oficial Flist.cva6 ✅)
- `cva6-master/corev_apu/src/ariane.sv` - Wrapper principal do CVA6
- `cva6-master/vendor/` - Dependências (AXI, common cells, etc)

**Arquivos Gerados:**
- ✅ `rtl/cores/cva6/files.f` - Lista de compilação (174 arquivos)
- ✅ `rtl/cores/cva6_real_wrapper.sv` - Wrapper com ACE adapter
- ✅ `scripts/generate_flist.py` - Script para regenerar Flist

---

## 🚀 Próximo Passo: Compilar com CVA6 Real

### Opção 1: Vivado (Recomendado)

```bash
# 1. Criar projeto Vivado com CVA6
cd c:\Users\rafae\Documents\trabalho final\syn\vivado

# 2. Executar script TCL (cria projeto com CVA6)
vivado -mode batch -source create_project_real_cva6.tcl

# 3. Compilar
vivado -mode batch -source build_project.tcl
```

### Opção 2: IVerilog/VCS (Para Simulação)

```bash
# 1. Compilar com includes do CVA6
cd c:\Users\rafae\Documents\trabalho final

# 2. Comando VCS
vcs -f rtl/cores/cva6/files.f -f rtl/files.f \\
    -top soc_top -sv \\
    -debug_all +lint=all

# 3. Simular
./simv
```

---

## 📋 Arquitetura do CVA6

O CVA6 real contém:
- **6-stage pipeline**: IF → ID → EX → MEM → WB → (bypass)
- **FPU**: Unidade de Ponto Flutuante (fpnew)
- **L1 Caches**: I$ e D$ (configurable, ~16KB cada)
- **WT Cache Subsystem**: Write-Through com coerência
- **MMU**: Virtual memory + TLB + PMP
- **CVXIF Interface**: Custom extensions support
- **AXI4 Master**: Para memória principal

---

## 🔧 Como Funciona a Integração

```
┌──────────────────────────────────────┐
│         CVA6 Real (ariane.sv)        │
│     (6-stage pipeline, FPU, caches)  │
└──────────────┬───────────────────────┘
               │ AXI4
               ▼
┌──────────────────────────────────────┐
│      AXI4→ACE Adapter                │
│  (snoop support, domain extension)   │
└──────────────┬───────────────────────┘
               │ AXI4+ACE
               ▼
┌──────────────────────────────────────┐
│         Our SoC (soc_top.sv)         │
│  ┌────────────────────────────────┐  │
│  │    CCU (Cache Coherency)       │  │
│  │    LLC (Shared L2 Cache)       │  │
│  │    Memory Controller           │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

---

## 📊 Tamanho do CVA6

```
✅ Total: 174 arquivos RTL
   - Core: ~45KB de RTL
   - FPU: ~120KB 
   - Cache: ~30KB
   - Vendor (AXI, utils): ~50KB

⚠️  Compilação vai levar:
   - Vivado: ~2-5 min
   - VCS: ~1-2 min
   - xsim (Vivado): ~3-8 min
```

---

## 🧪 Testes Recomendados

### 1. **Teste de Compilação** (Validar syntax)
```bash
# Apenas compile, sem simulate
vcs -f rtl/cores/cva6/files.f -f rtl/files.f -top soc_top -sv -lint
```

### 2. **Teste Estrutural** (Conectividade)
```bash
cd uvm_tb
make compile TEST=base_test
make simulate TEST=base_test
# Esperado: Passar sem erros de conexão
```

### 3. **Teste de Coerência** (CRÍTICO)
```bash
make simulate TEST=coherency_test
# Esperado: Snoops being processados corretamente
# Buscar: "snoop_valid", "cache_state", "write_invalidate"
```

### 4. **Stress Test** (2 cores ativos)
```bash
make simulate TEST=stress_test SEED=42
# Esperado: 100 transações sem deadlock
```

---

## ⚙️ Configurações do CVA6

O `ariane.sv` usa configurações definidas em:
- `cva6-master/core/include/config_pkg.sv`
- `cva6-master/core/include/cva6_pkg.sv`
- `cva6-master/vendor/pulp-platform/axi/include/axi_pkg.sv`

**Parâmetros principais:**
```systemverilog
CVA6Cfg.XLEN = 64              // 64-bit processor
CVA6Cfg.AxiAddrWidth = 32      // 32-bit address
CVA6Cfg.AxiDataWidth = 64      // 64-bit data
CVA6Cfg.AxiIdWidth = 4         // 4-bit transaction ID
```

Para customizar, editar:
```
rtl/cores/cva6-master/core/include/config_pkg.sv
```

---

## 📝 Troubleshooting

### Erro: "Package not found: cva6_pkg"
**Problema**: Include paths incorretos
**Solução**: Verificar que `files.f` contém todas as linhas `+incdir+...`

```bash
grep "+incdir+" rtl/cores/cva6/files.f | wc -l
# Esperado: >5 linhas
```

### Erro: "ariane.sv: Undef module"
**Problema**: Arquivos do CVA6 não estão no Flist
**Solução**: Regenerar com script

```bash
python scripts/generate_flist.py
# Deve ser: "✅ Arquivo gerado... Total de linhas: 174"
```

### Simulação muito lenta
**Problema**: Compilando com otimizações baixas
**Solução**: Adicionar flags VCS

```bash
vcs ... +define+SIMULATION -O2
```

---

## 📞 Verificação Rápida

Executar este comando para validar tudo:

```bash
cd c:\Users\rafae\Documents\trabalho final

# 1. Verificar Flist
echo "=== Checking Flist ===" && \
    wc -l rtl/cores/cva6/files.f && \
    grep -c "\.sv$\|\.v$" rtl/cores/cva6/files.f

# 2. Verificar wrapper
echo "=== Checking Wrapper ===" && \
    grep -c "cva6_ace_adapter\|ariane" rtl/cores/cva6_real_wrapper.sv

# 3. Verificar arquivos principais do CVA6
echo "=== Checking CVA6 Core ===" && \
    find rtl/cores/cva6-master/core -name "cva6.sv" -o -name "ariane.sv" -o -name "*_pkg.sv" | wc -l

# Resultado esperado: >50 arquivos encontrados
```

---

## 🎯 Próximas Ações

**Imediato (agora):**
1. ✅ Repositório CVA6 clonado
2. ✅ Flist gerado (174 arquivos)
3. ✅ Wrapper criado
4. ▶ **Compilar com Vivado ou VCS**

**Curto prazo (próx 1h):**
5. ▶ Executar `base_test` (validar conexão)
6. ▶ Executar `coherency_test` (validar coerência)

**Médio prazo (próx 4h):**
7. ▶ Executar `stress_test` (validar dual-core)
8. ▶ Análise de performance (IPC, cache hit rate)

**Longo prazo:**
9. ▶ Síntese com Vivado
10. ▶ Place & Route
11. ▶ Geração de bitstream

---

## 💾 Limpeza de Cache (se precisar)

Caso queira compilar novamente do zero:

```bash
# Remover artifacts
rm -rf sim/ *.log *.wdb dump.vcd

# Regenerar Flist (se necessário)
cd rtl/cores/cva6-master/core
python ../../scripts/generate_flist.py

# Recompilar
cd ../../../
make -C uvm_tb clean
make -C uvm_tb compile
```

---

**Resumo Final**: Você tem tudo pronto!  
CVA6 real está no lugar certo, Flist gerado, wrapper criado.
Próximo passo é apenas compilar com VCS/Vivado e rodar os testes UVM.  
Qualquer dúvida sobre compilação, vem! 🚀

