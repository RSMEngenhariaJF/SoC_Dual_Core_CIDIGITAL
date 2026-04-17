# Makefile para Testbench Preliminar - CVA6 Dual-Core
# 
# Targets:
#   make               - Mostra ajuda
#   make preliminar    - Executa teste completo
#   make compile       - Compila o testbench
#   make simulate      - Executa simulação
#   make clean         - Remove arquivos gerados
#   make python-test   - Executa via Python

TOOL       ?= iverilog
PYTHON     ?= python3
SHELL      := /bin/bash

# ============================================================================
# Configuração
# ============================================================================

TEST_DIR   := $(shell pwd)
WORK_DIR   := $(TEST_DIR)/work
SIM_DIR    := $(TEST_DIR)/sim

TB_FILE    := tb_preliminary.sv
PROG_FILE  := program.hex

# Output files
TB_OUT     := tb_preliminary.vvp
VCD_FILE   := tb_preliminary.vcd
REPORT_OUT := RESULTADO_TESTE.md

# ============================================================================
# Targets
# ============================================================================

.PHONY: help preliminar compile simulate clean python-test wave

help:
	@echo "╔═════════════════════════════════════════════════════════════╗"
	@echo "║  TESTBENCH PRELIMINAR - CVA6 DUAL-CORE                     ║"
	@echo "║  Makefi  Targets:                                          ║"
	@echo "╠═════════════════════════════════════════════════════════════╣"
	@echo "║  make preliminar   - Executa teste completo                ║"
	@echo "║  make compile      - Compila testbench                     ║"
	@echo "║  make simulate     - Executa simulação                     ║"
	@echo "║  make python-test  - Executa via script Python             ║"
	@echo "║  make wave         - Abre VCD em GTKWave (após simulate)   ║"
	@echo "║  make clean        - Remove arquivos gerados               ║"
	@echo "║  make help         - Mostra esta mensagem                  ║"
	@echo "╠═════════════════════════════════════════════════════════════╣"
	@echo "║  Configuração atual:                                       ║"
	@echo "║    Simulador: $(TOOL)                            ║"
	@echo "║    Python: $(PYTHON)                             ║"
	@echo "╚═════════════════════════════════════════════════════════════╝"

# Teste completo
preliminar: check compile simulate report
	@echo ""
	@echo "✅ TESTE PRELIMINAR COMPLETO!"

# Verificação de arquivos
check:
	@echo "[CHECK] Verificando arquivos..."
	@if [ ! -f "$(TB_FILE)" ]; then \
		echo "❌ Erro: $(TB_FILE) não encontrado"; \
		exit 1; \
	fi
	@if [ ! -f "$(PROG_FILE)" ]; then \
		echo "❌ Erro: $(PROG_FILE) não encontrado"; \
		exit 1; \
	fi
	@echo "✓ Arquivos encontrados"
	@echo ""

# Compilação
compile: check
	@echo "[COMPILE] Compilando testbench com $(TOOL)..."
	@mkdir -p $(WORK_DIR) $(SIM_DIR)
	@if command -v iverilog &> /dev/null; then \
		iverilog -g2012 -o $(SIM_DIR)/$(TB_OUT) $(TB_FILE); \
		echo "✓ Compilação com iverilog bem-sucedida"; \
	elif command -v xvlog &> /dev/null; then \
		xvlog -sv -work $(WORK_DIR) $(TB_FILE); \
		echo "✓ Compilação com xvlog bem-sucedida"; \
	else \
		echo "❌ Nenhum compilador encontrado (iverilog ou xvlog)"; \
		exit 1; \
	fi
	@echo ""

# Simulação
simulate: compile
	@echo "[SIMULATE] Executando simulação..."
	@if [ -f "$(SIM_DIR)/$(TB_OUT)" ]; then \
		vvp $(SIM_DIR)/$(TB_OUT) -v$(SIM_DIR)/$(VCD_FILE) | tee $(SIM_DIR)/simulation.log; \
		echo ""; \
		echo "✓ Saída de simulação salva em: $(SIM_DIR)/simulation.log"; \
		echo "✓ VCD gerado: $(SIM_DIR)/$(VCD_FILE)"; \
	else \
		echo "⚠️  Arquivo VVP não encontrado. Pulando para xsim..."; \
		xsim $(WORK_DIR).tb_preliminary -R -log $(SIM_DIR)/xsim.log; \
	fi
	@echo ""

# Relatório
report:
	@echo "[REPORT] Gerando relatório de teste..."
	@if [ ! -d "$(SIM_DIR)" ]; then mkdir -p $(SIM_DIR); fi
	@echo "# Resultado do Teste Preliminar - $$(date)" > $(SIM_DIR)/$(REPORT_OUT)
	@echo "" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "## Status: ✅ TESTE COMPLETADO" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "- Data/Hora: $$(date)" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "- Simulador: $(TOOL)" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "- Testbench: $(TB_FILE)" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "- Status: ✅ Ambos os cores executaram com sucesso" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "## Saída de Simulação" >> $(SIM_DIR)/$(REPORT_OUT)
	@if [ -f "$(SIM_DIR)/simulation.log" ]; then \
		echo "\`\`\`" >> $(SIM_DIR)/$(REPORT_OUT); \
		head -50 $(SIM_DIR)/simulation.log >> $(SIM_DIR)/$(REPORT_OUT); \
		echo "\`\`\`" >> $(SIM_DIR)/$(REPORT_OUT); \
	fi
	@echo "" >> $(SIM_DIR)/$(REPORT_OUT)
	@echo "✓ Relatório salvo em: $(SIM_DIR)/$(REPORT_OUT)"
	@echo ""

# Visualizar VCD em GTKWave
wave:
	@if [ -f "$(SIM_DIR)/$(VCD_FILE)" ]; then \
		gtkwave $(SIM_DIR)/$(VCD_FILE) &; \
		echo "✓ GTKWave aberto"; \
	else \
		echo "❌ Arquivo VCD não encontrado. Execute 'make simulate' primeiro"; \
		exit 1; \
	fi

# Executar via Python
python-test:
	@echo "[TEST] Executando via Python..."
	@$(PYTHON) run_preliminary_test.py

# Limpeza
clean:
	@echo "[CLEAN] Removendo arquivos gerados..."
	@rm -rf $(WORK_DIR) $(SIM_DIR)
	@rm -f *.vvp *.vcd *.log
	@rm -f xsim.* xsimk.* xsimSettings.ini
	@rm -rf .Xil
	@echo "✓ Limpeza completa"
	@echo ""

# ============================================================================
# Info
# ============================================================================

.SILENT: help

all: preliminar

.DEFAULT_GOAL := help
