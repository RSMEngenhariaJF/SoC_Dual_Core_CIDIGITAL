# 🔧 O que é o Wrapper Real do CVA6?

**Data**: 16 de Abril de 2026  
**Objetivo**: Entender a diferença entre wrapper behavioral e wrapper real

---

## 📚 Conceito Básico

Um **wrapper** é um módulo que **encapsula** (embrulha) outro módulo. Pense como uma caixa que contém algo dentro.

```
┌─────────────────────────────────┐
│   WRAPPER (Caixa Externa)       │
│  ┌──────────────────────────┐   │
│  │  Módulo Real (Conteúdo)  │   │
│  └──────────────────────────┘   │
│   Interface Padronizada         │
└─────────────────────────────────┘
```

---

## 🔴 Wrapper Behavioral (FAKE)

Seu projeto **atualmente usa** este tipo:

```systemverilog
// ❌ VERSÃO ATUAL (FAKE)
module cva6_wrapper #(
    parameter CVA6_CORE_ID = 0
) (
    input clk_i,
    input rst_ni,
    ace_bus.master ace,
    // ... outros sinais
);

// Simplesmente "finge" ser um CVA6
// Gera transações pré-programadas
// NÃO executa código real RISC-V
// Apenas simula comportamento

// Exemplo: ao invés de REALMENTE executar uma instrução RISC-V,
// apenas simula como se tivesse executado

always_ff @(posedge clk_i) begin
    // Código simulado, não real
    simulated_pc <= simulated_pc + 4;
end

endmodule
```

### Características:
- ✅ Rápido para simular
- ✅ Fácil de escrever
- ❌ **Não é o CVA6 real**
- ❌ Não executa instruções reais
- ❌ Não reflete timing real
- ❌ Não valida pipeline real

### Quando usar:
- Testes iniciais de conectividade
- Debugging do barramento ACE
- Validação de interface
- **NÃO para produção**

---

## 🟢 Wrapper Real

Este é o **objetivo final** do seu projeto:

```systemverilog
// ✅ VERSÃO REAL (INTEGRADA)
module cva6_real_wrapper #(
    parameter CVA6_CORE_ID = 0
) (
    input clk_i,
    input rst_ni,
    ace_bus.master ace,
    // ... outros sinais
);

// Instancia o VERDADEIRO CVA6
cva6 #(
    .CVA6_XLEN(64),
    .ASID_WIDTH(16),
    // ... outros parâmetros
) i_cva6 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .hart_id_i(CVA6_CORE_ID),
    
    // Interface AXI (saída do CVA6)
    .axi_req_o(axi_req),
    .axi_resp_i(axi_resp),
    
    // ... outros sinais
);

// Adaptador: AXI4 → ACE
// Converte sinais AXI4 para protocolo ACE
axi_to_ace_adapter i_adapter (
    .axi_req_i(axi_req),
    .axi_resp_o(axi_resp),
    .ace_o(ace),
    // ...
);

endmodule
```

### Características:
- ✅ **Executa instruções RISC-V reais**
- ✅ Reflete timing real do CVA6
- ✅ Valida completamente o pipeline
- ✅ Pode rodar bare-metal code
- ✅ Pronto para produção
- ❌ Mais lento na simulação
- ❌ Requer mais recursos

### Quando usar:
- ✅ Testes finais de coerência
- ✅ Validação de performance
- ✅ Produção/FPGA
- ✅ Testes com firmware real

---

## 📊 Comparação: Behavioral vs Real

| Aspecto | Behavioral | Real |
|---------|-----------|------|
| **O que é?** | Simulação fake | CVA6 verdadeiro |
| **Executa RISC-V?** | ❌ Não | ✅ Sim |
| **Timing?** | Simulado | Real |
| **Tamanho RTL** | ~100 linhas | ~50.000+ linhas |
| **Compila em** | Minutos | 5-10 minutos |
| **Simula em** | Rápido | Mais lento |
| **Testes ACE** | Básicos | Completos |
| **Produção?** | ❌ Não | ✅ Sim |
| **Arquivo** | `cva6_wrapper.sv` | `cva6_real_wrapper.sv` |

---

## 🎯 O que muda com o Wrapper Real?

### Antes (Behavioral)
```
┌─────────────────────────────┐
│   SoC Top (soc_top.sv)      │
│  ┌───────────────────────┐  │
│  │ cva6_wrapper (FAKE)   │  │
│  │ Apenas simula         │  │
│  └───────────────────────┘  │
└─────────────────────────────┘

Resultado: ⚠️ Conectividade OK, mas CVA6 não real
```

### Depois (Real)
```
┌─────────────────────────────────────────────┐
│       SoC Top (soc_top.sv)                  │
│  ┌────────────────────────────────────────┐ │
│  │   cva6_real_wrapper (REAL)             │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │  cva6 (VERDADEIRO 50K+ linhas) │  │ │
│  │  │  - Executa RISC-V               │  │ │
│  │  │  - Pipeline real                │  │ │
│  │  │  - Cache controller             │  │ │
│  │  │  - MMU, CSR, etc                │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │  AXI→ACE Adapter (conversor)    │  │ │
│  │  └──────────────────────────────────┘  │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘

Resultado: ✅ Sistema completo, pronto produção
```

---

## 🔄 Como o Wrapper Real Funciona?

### Passo 1: Instanciar CVA6 Real
```systemverilog
cva6 i_cva6 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .hart_id_i(CORE_ID),
    .axi_req_o(axi_req),      // ← Saída em formato AXI4
    .axi_resp_i(axi_resp),    // ← Entrada em formato AXI4
);
```

### Passo 2: Adaptar AXI4 para ACE
```systemverilog
// CVA6 fala AXI4
// Nós precisamos ACE para coerência
axi_to_ace_adapter i_adapter (
    .axi_req_i(axi_req),      // Pega AXI4 de entrada
    .axi_resp_o(axi_resp),    // Envia AXI4 de saída
    .ace_bus(ace)             // Comunica via ACE
);
```

### Passo 3: Conectar ao Barramento ACE
```systemverilog
// Agora o wrapper se conecta como mestre ACE
// Pode fazer snoops, coherency, etc
ace_bus.master ace  // Interface com CCU
```

---

## 📁 Estrutura de Arquivos

```
rtl/cores/
│
├── cva6_wrapper.sv           ❌ BEHAVIORAL (atualmente ativo)
│   └─ Versão fake, simula
│
├── cva6_real_wrapper.sv      ✅ REAL (FALTA CRIAR)
│   ├─ Instancia o CVA6 real
│   ├─ Adaptador AXI→ACE
│   └─ Conecta ao barramento
│
├── cva6/                     ⏳ VAZIO (falta executar integrate_cva6.py)
│   ├─ cva6.sv               (será copiado)
│   ├─ alu.sv
│   ├─ branch_unit.sv
│   └─ ... 50+ arquivos mais
│
└── cva6-master/             ✅ Clone do GitHub
    └─ (metadados)
```

---

## 🚀 O que precisa fazer?

### Fase 1: Conseguir o CVA6 Real ⏳
```bash
python scripts/integrate_cva6.py
# Resultado: arquivos CVA6 em rtl/cores/cva6/
```

### Fase 2: Criar o Wrapper Real 🔧
```bash
# Arquivo: rtl/cores/cva6_real_wrapper.sv
# Conteúdo: 
#   - Instancia cva6
#   - Adaptador AXI→ACE
#   - Mapeia sinais
```

### Fase 3: Atualizar soc_top.sv 📝
```bash
# Mudar:
#   cva6_wrapper    →  cva6_real_wrapper
# Resultado: Sistema real funcionando
```

---

## 💡 Analogia do Mundo Real

Imagine um **simulador de carros**:

### ❌ Wrapper Behavioral
```
Você está em um simulador de vídeo game (Gran Turismo)
- "Parece" um carro
- Segue leis de física
- Mas é tudo simulado
- Não é um carro real
```

### ✅ Wrapper Real
```
Você está dirigindo um carro REAL
- Verdadeiros cilindros funcionando
- Motor real fazendo barulho
- Pneus reais derrapando
- Peças reais desgastando
```

O **wrapper real é como passar do simulador para o carro de verdade**.

---

## 📊 Timeline de Mudanças

```
HOJE (16/04):  ❌ Usando cva6_wrapper (fake)
               Sistema funciona mas CVA6 não é real

SEMANA 1:      ✅ Executar integrate_cva6.py
               📦 Tenho CVA6 real em rtl/cores/cva6/

DEPOIS:        ✅ Criar cva6_real_wrapper.sv
               🔌 Conectar CVA6 real ao sistema

DEPOIS:        ✅ Atualizar soc_top.sv
               ✨ Sistema 100% real funcionando
```

---

## 🎯 Importância para seu Projeto

| Antes (Behavioral) | Depois (Real) |
|------------------|--------------|
| Testes apenas ACE | ✅ Testes CCU + CVA6 |
| Sem instrução RISC-V | ✅ Executa código ARM |
| Sem pipeline real | ✅ Validação pipeline |
| Sem timing real | ✅ Análise performance |
| **Não pronto produção** | ✅ **Pronto produção** |

---

## ❓ FAQ

**P: Posso usar only behavioral?**  
Não, você quer testar o CVA6 real. Sem wrapper real, não funciona.

**P: Quanto tempo leva criar wrapper real?**  
~30-45 minutos com template pronto.

**P: Wrapper real vai quebrar meus testes UVM?**  
Não! Testes UVM são agnósticos (funcionam com ambos).

**P: Qual é mais rápido?**  
Behavioral é mais rápido simular. Real é mais realista.

**P: Por que dois tipos?**  
Behavioral é para debug rápido. Real é para validação completa.

---

## 🔗 Documentos Relacionados

- [INTEGRACAO_CVA6_REAL.md](../INTEGRACAO_CVA6_REAL.md) ← Passo-a-passo integração
- [ANALISE_PROJETO.md](../ANALISE_PROJETO.md) ← Status do projeto
- [README.md](../README.md) ← Quick start

---

## ✅ Resumo em 1 Frase

> **Wrapper Real = CVA6 de verdade executando instruções RISC-V real, em vez de fake/simulado**

🚀 Próximo passo: Execute `python scripts/integrate_cva6.py`
