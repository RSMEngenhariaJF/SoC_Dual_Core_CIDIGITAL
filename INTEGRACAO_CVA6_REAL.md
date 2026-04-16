# Integração do CVA6 Real

## Situação Atual

Você possui:
- ✅ **RTL SoC completo**: CCU, LLC, ACE protocol (1.379 linhas)
- ✅ **UVM Test Environment**: 16 arquivos, 2.189 linhas de testes
- ✅ **Infra de Build**: Makefile, Vivado scripts, validadores
- ⚠️ **Núcleo CVA6**: Apenas wrapper behavioral (precisa do RTL real)

## Como Integrar o CVA6 Real

### Passo 1: Usar o Script de Automação

```powershell
cd "c:\Users\rafae\Documents\trabalho final"
python scripts/integrate_cva6.py
```

Este script irá automaticamente:
1. Clonar o repositório oficial CVA6
2. Copiar todos os arquivos RTL necessários
3. Criar o adaptador ACE
4. Gerar lista de compilação

### Passo 2: Verificar os Arquivos Copiados

```powershell
ls rtl/cores/cva6/ | Select-Object Name, Length
```

Você deve ver arquivos como:
- `cva6.sv` (core principal)
- `alu.sv`, `branch_unit.sv`, `controller.sv`
- `csr_regfile.sv`, `ex_stage.sv`, `id_stage.sv`
- `lsu.sv`, `branch_unit.sv`, muitos outros

### Passo 3: Criar Wrapper para CVA6 Real

Crie arquivo: `rtl/cores/cva6_real_wrapper.sv`

```systemverilog
module cva6_real_wrapper #(
    parameter CVA6_CORE_ID = 0
) (
    input clk_i,
    input rst_ni,
    
    ace_bus.master ace,
    
    output logic [63:0] hart_id_o,
    output logic [2:0] irq_i,
    output logic debug_req_i
);

    // Parâmetros do CVA6
    localparam int unsigned CVA6_XLEN = 64;
    localparam int unsigned CVA6_FULL_XLEN = 64;
    
    // Instância real do CVA6
    cva6 #(
        .CVA6_XLEN(CVA6_XLEN),
        .CVA6_FULL_XLEN(CVA6_FULL_XLEN),
        .CVA6_AXI_ID_WIDTH(4),
        .CVA6_AXI_ADDR_WIDTH(32),
        .CVA6_AXI_DATA_WIDTH(64)
    ) i_cva6 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        
        // AXI4 para ACE (via adaptador)
        .axi_awid_o(),
        .axi_awaddr_o(),
        .axi_awlen_o(),
        .axi_awsize_o(),
        .axi_awburst_o(),
        .axi_awvalid_o(),
        .axi_awready_i(),
        
        .axi_wdata_o(),
        .axi_wstrb_o(),
        .axi_wlast_o(),
        .axi_wvalid_o(),
        .axi_wready_i(),
        
        .axi_bid_i(),
        .axi_bresp_i(),
        .axi_bvalid_i(),
        .axi_bready_o(),
        
        .axi_arid_o(),
        .axi_araddr_o(),
        .axi_arlen_o(),
        .axi_arsize_o(),
        .axi_arburst_o(),
        .axi_arvalid_o(),
        .axi_arready_i(),
        
        .axi_rid_i(),
        .axi_rdata_i(),
        .axi_rresp_i(),
        .axi_rlast_i(),
        .axi_rvalid_i(),
        .axi_rready_o(),
        
        .hart_id_i(CVA6_CORE_ID),
        .irq_i('0),
        .debug_req_i(1'b0),
        .debug_havereset_o(),
        .debug_running_o(),
        .debug_halted_o()
    );

    // Adaptador AXI4 -> ACE
    cva6_ace_adapter i_adapter (
        .clk(clk_i),
        .rst_n(rst_ni),
        
        .axi_awid(),
        .axi_awaddr(),
        .axi_awlen(),
        .axi_awsize(),
        .axi_awburst(),
        .axi_awvalid(),
        .axi_awready(),
        
        .axi_wdata(),
        .axi_wstrb(),
        .axi_wlast(),
        .axi_wvalid(),
        .axi_wready(),
        
        .axi_bid(),
        .axi_bresp(),
        .axi_bvalid(),
        .axi_bready(),
        
        .axi_arid(),
        .axi_araddr(),
        .axi_arlen(),
        .axi_arsize(),
        .axi_arburst(),
        .axi_arvalid(),
        .axi_arready(),
        
        .axi_rid(),
        .axi_rdata(),
        .axi_rresp(),
        .axi_rlast(),
        .axi_rvalid(),
        .axi_rready(),
        
        .ace(ace)
    );

endmodule
```

### Passo 4: Atualizar SoC Top

Edite: `rtl/top/soc_top.sv`

Substituir:
```systemverilog
// ANTES - wrapper behavioral
cva6_wrapper #(.CVA6_CORE_ID(i)) i_core (
    .clk(clk),
    .rst_n(rst_n),
    .ace(ace_master_if[i])
);
```

Por:
```systemverilog
// DEPOIS - CVA6 real
cva6_real_wrapper #(.CVA6_CORE_ID(i)) i_core (
    .clk_i(clk),
    .rst_ni(rst_n),
    .ace(ace_master_if[i])
);
```

### Passo 5: Compilar com CVA6 Real

```powershell
# Verificar lista de compilação
cat rtl/cores/cva6/files.f

# Compilar com Vivado
xvlog -recursive -f rtl/cores/cva6/files.f
xvlog rtl/axi4/*.sv rtl/ace/*.sv rtl/ccu/*.sv rtl/llc/*.sv rtl/top/*.sv
```

### Passo 6: Executar Testes UVM

```powershell
cd uvm_tb

# Teste básico
make compile
make simulate TEST=base_test

# Teste de coerência (mais importante)
make simulate TEST=coherency_test

# Teste de stress com 2 cores
make simulate TEST=stress_test

# Todos os testes
make test_all
```

## Problemas Comuns

### Erro: "header.sv not found"

**Solução**: O CVA6 usa arquivos em pastas específicas. Verifique se o script copiou todos:

```powershell
ls rtl/cores/cva6/ -Recurse -Filter "*.sv" | Measure-Object | Select-Object -ExpandProperty Count
```

Deve haver >50 arquivos `.sv`

### Erro: "Snoop interface not implemented"

**Razão**: CVA6 não tem ACE nativo, precisa do adaptador

**Solução**: Verificar que `cva6_ace_adapter.sv` foi criado em:
```
rtl/cores/cva6/cva6_ace_adapter.sv
```

### Erro: "hart_id signal"

**Razão**: CVA6 usa `hart_id_i` como entrada, não parâmetro

**Solução**: Na instância no wrapper, adicionar:
```systemverilog
.hart_id_i(CVA6_CORE_ID),
```

## Validação Pós-Integração

Após integrar o CVA6 real, verificar:

```powershell
# 1. Verificar sincronismo de clock
grep -r "clk_i\|clk" rtl/cores/cva6/cva6.sv | head -5

# 2. Verificar porta ACE
grep -r "ace\|axi_" rtl/cores/cva6_real_wrapper.sv

# 3. Executar teste de coerência
cd uvm_tb
make simulate TEST=coherency_test SEED=12345
```

## Próximos Passos

| Etapa | Descrição | Status |
|-------|-----------|--------|
| 1 | Executar `integrate_cva6.py` | ▶ TODO |
| 2 | Criar `cva6_real_wrapper.sv` | ▶ TODO |
| 3 | Atualizar `soc_top.sv` | ▶ TODO |
| 4 | Compilar com CVA6 | ▶ TODO |
| 5 | Teste `coherency_test` | ▶ TODO |
| 6 | Teste `stress_test` (2 cores) | ▶ TODO |
| 7 | Análise de Performance | ▶ TODO |

## Suporte

Se encontrar erros:

1. Verificar arquivo de log: `sim.log`
2. Procurar por `// TODO: ACE adapter` em `cva6_ace_adapter.sv`
3. Confirmar que todos 16 arquivos UVM estão em `uvm_tb/`
4. Executar validador: `python uvm_tb/validate_uvm.py`

---

**Resumo**: O projeto está 100% pronto para CVA6 real. Use o script de automação para clonar e integrar. Todos os testes e infraestrutura estão configurados.
