# 🗺️ Roadmap Técnico - SoC Dual-Core CVA6 ACE

**Última Atualização**: 16 de Abril de 2026  
**Responsável**: RSM Engenharia JF  
**Status Geral**: 🟡 **85% Completo**

---

## 📊 Visão Geral de Progresso

```
Fases do Projeto:

Phase 1: Preparação       ✅✅✅✅✅ 100% COMPLETO
  └─ RTL Design          ✅ 1.379 linhas
  └─ UVM Framework       ✅ 2.189 linhas
  └─ Build System        ✅ 8 scripts
  └─ Documentação        ✅ 6 guias

Phase 2: Integração CVA6 🔴🔴🔴⚪⚪ 0% (BLOQUEANTE)
  └─ Clone CVA6          ⏳ TODO
  └─ Wrapper Real        ⏳ TODO
  └─ Update soc_top.sv   ⏳ TODO
  └─ Lista compilação    ⏳ TODO

Phase 3: Compilação      ⏳⏳⏳⏳⏳ 0% (aguarda P2)
  └─ RTL Compilation     ⏳ TODO
  └─ Simulação           ⏳ TODO
  └─ Coverage            ⏳ TODO

Phase 4: Testes UVM      ⏳⏳⏳⏳⏳ 0% (aguarda P2)
  └─ Unit Tests          ⏳ TODO
  └─ Integration Tests   ⏳ TODO
  └─ Performance Tests   ⏳ TODO

Phase 5: Síntese FPGA    ⏳⏳⏳⏳⏳ 0% (aguarda P3)
  └─ Vivado Build        ⏳ TODO
  └─ Place & Route       ⏳ TODO
  └─ Timing Analysis     ⏳ TODO

Phase 6: Produção        ⏳⏳⏳⏳⏳ 0% (aguarda P5)
  └─ Release Prep        ⏳ TODO
  └─ Documentation       ⏳ TODO
  └─ Deployment          ⏳ TODO
```

---

## 📅 Timeline Estimado

### WEEK 1: Integração CVA6 (CRÍTICA) 🔴

| Dia | Tarefa | Duração | Responsável | Status |
|-----|--------|---------|-------------|--------|
| **Seg** | Executar `integrate_cva6.py` | 15 min | Dev | ⏳ TODO |
| **Ter** | Revisar arquivos copiados | 30 min | QA | ⏳ TODO |
| **Qua** | Criar `cva6_real_wrapper.sv` | 45 min | Dev | ⏳ TODO |
| **Qui** | Atualizar `soc_top.sv` | 20 min | Dev | ⏳ TODO |
| **Sex** | Teste compilação básico | 1h | QA | ⏳ TODO |

**Marcos**: Primeira compilação com CVA6 real  
**Risco**: ⚠️ Pode encontrar problemas de compatibilidade

---

### WEEK 2: Compilação & Testes Iniciais 🟡

| Dia | Tarefa | Duração | Responsável | Status |
|-----|--------|---------|-------------|--------|
| **Seg** | Resolver erros de compilação | 2-3h | Dev | ⏳ TODO |
| **Ter/Qua** | Executar UVM tests básicos | 2h | QA | ⏳ TODO |
| **Qui** | Teste `coherency_test` | 1h | QA | ⏳ TODO |
| **Sex** | Análise de resultados | 1h | Lead | ⏳ TODO |

**Marcos**: Todos os tests básicos passando  
**Entrega**: Relatório de cobertura UVM

---

### WEEK 3: Otimização & Síntese 🟠

| Dia | Tarefa | Duração | Responsável | Status |
|-----|--------|---------|-------------|--------|
| **Seg/Ter** | Performance analysis | 2h | Dev | ⏳ TODO |
| **Qua** | Setup Vivado project | 1h | Dev | ⏳ TODO |
| **Qui** | Síntese RTL | 3-4h | Dev | ⏳ TODO |
| **Sex** | Timing analysis | 2h | QA | ⏳ TODO |

**Marcos**: RTL sintetizado sem timing violations  
**Entrega**: Relatório de recursos FPGA

---

### WEEK 4+: Produção 🟡

```
├─ Deploy para Hardware
├─ Testes em silício
├─ Documentação final
└─ Release v1.0
```

---

## 🎯 Métricas de Sucesso

### Phase 2 (Integração)
- ✅ Todos arquivos CVA6 copiados (~50+ SV files)
- ✅ Compilation sem erros
- ✅ Wrapper real funcional
- ✅ GitHub atualizado

### Phase 3 (Compilação)
- ✅ RTL compile time < 5 min
- ✅ 0 erros de sintaxe
- ✅ Warnings removíveis

### Phase 4 (Tests UVM)
- ✅ 6/6 test cases passar
- ✅ Coverage UVM > 80%
- ✅ Coerência MOESI validada

### Phase 5 (FPGA)
- ✅ Síntese sem críticos erros
- ✅ Timing < 100MHz
- ✅ Resource utilization < 60%

---

## 🔴 Dependências Críticas

```
Phase 2 (CVA6 Real)
    ↓ BLOQUEANTE para
Phase 3 (Compilação)
    ↓ BLOQUEANTE para
Phase 4 (Testes)
    ↓ BLOQUEANTE para
Phase 5 (FPGA)
    ↓ BLOQUEANTE para
Phase 6 (Produção)
```

**Gargalo Atual**: ⏸️ Aguardando **integração CVA6 real** (Phase 2)

---

## 🛠️ Ações Imediatas Necessárias

### ✋ STOP - EXECUTE AGORA (15 min)
```powershell
cd "c:\Users\rafae\Documents\trabalho final"
python scripts/integrate_cva6.py

# Se sucesso:
ls rtl/cores/cva6/ | Measure-Object
# Esperado: número > 40
```

### ↪️ DEPOIS (30 min)
```powershell
# Revisar documentação
notepad INTEGRACAO_CVA6_REAL.md

# Seguir Passo 3: Criar wrapper real
# Template em: INTEGRACAO_CVA6_REAL.md linha ~50
```

### ✔️ DEPOIS-DEPOIS (20 min)
```powershell
# Atualizar soc_top.sv
# Substituir: cva6_wrapper  →  cva6_real_wrapper
```

---

## 📊 Breakdown de Esforço

| Fase | Horas | Estado | Bloqueado? |
|------|-------|--------|-----------|
| **Phase 1: Preparação** | ✅ 40h | COMPLETO | ❌ |
| **Phase 2: CVA6 Real** | ⏳ 3-4h | CRÍTICA | 🔴 SIM |
| **Phase 3: Compilação** | ⏳ 5-8h | Aguarda P2 | 🔴 SIM |
| **Phase 4: Testes UVM** | ⏳ 8-12h | Aguarda P3 | 🔴 SIM |
| **Phase 5: FPGA** | ⏳ 10-15h | Aguarda P4 | 🔴 SIM |
| **Phase 6: Produção** | ⏳ 4-6h | Aguarda P5 | 🔴 SIM |
| **TOTAL** | **~80h** | **15% DONE** | |

---

## 🎓 Lições Aprendidas & Best Practices

### O que funcionou bem ✅
- Arquitetura modular de RTL
- Separação clara de concerns (UVM)
- Build system automatizado
- Documentação abrangente

### Áreas para melhoria 🔄
- CI/CD pipeline ainda não configurado
- Falta testes de integração em hardware
- Performance profiling pode ser expandido

### Recomendações 💡
1. Usar GitHub Actions para automated builds
2. Adicionar coverage report automatizado
3. Implementar design review checklist
4. Versionar releases com Git tags

---

## 👥 Responsabilidades

| Papel | Tarefa Principal | Deadline |
|------|-----------------|----------|
| **DevLead** | Supervisar P2 integration | 20/04/2026 |
| **RTL Dev** | Criar `cva6_real_wrapper.sv` | 18/04/2026 |
| **QA/Tester** | Validar compilação | 22/04/2026 |
| **DevOps** | Setup CI/CD | 27/04/2026 |
| **Doc Lead** | Finalizar documentação | 01/05/2026 |

---

## 📞 Escalação de Riscos

### Risk 1: CVA6 Real não compila 🔴
- **Probabilidade**: Média
- **Impacto**: Alto (bloqueia tudo)
- **Mitigação**: Testar compilação isolada do CVA6
- **Plano B**: Usar versão behavioral por mais tempo

### Risk 2: Timing violations em FPGA 🟡
- **Probabilidade**: Média
- **Impacto**: Médio
- **Mitigação**: Pipeline design, place & route iterativo
- **Plano B**: Reduzir clock frequency

### Risk 3: Performance degradada 🟡
- **Probabilidade**: Média
- **Impacto**: Médio
- **Mitigação**: Early profiling, cache tuning
- **Plano B**: Aumentar LLC size

---

## 📄 Documentação de Referência

| Doc | Propósito | Local |
|-----|-----------|-------|
| **ANALISE_PROJETO.md** | Status completo + checklist | [link](./ANALISE_PROJETO.md) |
| **README.md** | Quick start | [link](./README.md) |
| **INTEGRACAO_CVA6_REAL.md** | Phase 2 step-by-by-step | [link](./INTEGRACAO_CVA6_REAL.md) |
| **RESUMO_FINAL.md** | Visão geral arquitetura | [link](./RESUMO_FINAL.md) |
| **CHECKLIST_INTEGRACAO.md** | Detailed checklist | [link](./CHECKLIST_INTEGRACAO.md) |

---

## ✅ Sign-Off

**Última Revisão**: 16/04/2026  
**Revisado por**: [Seu Nome]  
**Status Aprovado**: 🟡 AMBER (aguardando Phase 2)  

**Próximo Review**: 20/04/2026 (post-integração CVA6)

---

> 🚀 **Próximo Passo**: Execute `python scripts/integrate_cva6.py` e comece a Phase 2!
