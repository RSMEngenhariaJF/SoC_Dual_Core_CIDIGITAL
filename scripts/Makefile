# Makefile para SoC Dual-Core CVA6 com Coerência ACE
# 
# Targets:
#   make compile - Compila o projeto
#   make simulate - Executa simulação
#   make all - Compila e simula
#   make clean - Remove arquivos gerados

TOOL       = iverilog
SIM_TOOL   = vvp
GTKWAVE    = gtkwave

SRC_DIR    = ../rtl
TB_DIR     = ../tb
SIM_DIR    = .

# Arquivos de Design
RTL_FILES  = \
	$(SRC_DIR)/axi4/axi4_defines.sv \
	$(SRC_DIR)/ace/ace_bus.sv \
	$(SRC_DIR)/cores/cva6_wrapper.sv \
	$(SRC_DIR)/ccu/ccu.sv \
	$(SRC_DIR)/llc/llc.sv \
	$(SRC_DIR)/top/soc_top.sv

# Arquivo de Testbench
TB_FILES   = $(TB_DIR)/tb_soc_top.sv

# Alvo de Output
OUT_FILE   = soc_top.vvp
VCD_FILE   = soc_top.vcd
OBJ_DIR    = obj_dir

all: compile simulate

compile: $(RTL_FILES) $(TB_FILES)
	@echo "Compilando SoC DUAL-CORE CVA6 com ACE Coherency..."
	$(TOOL) -g2012 -o $(OUT_FILE) $(RTL_FILES) $(TB_FILES)
	@echo "Compilação concluída!"

simulate: $(OUT_FILE)
	@echo "Executando simulação..."
	$(SIM_TOOL) -v$(VCD_FILE) $(OUT_FILE)
	@echo "Simulação concluída! VCD gerado: $(VCD_FILE)"

wave: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE) -v 2>/dev/null &

clean:
	@echo "Limpando arquivos temporários..."
	rm -f $(OUT_FILE) $(VCD_FILE) *.vcd
	rm -rf $(OBJ_DIR)
	@echo "Limpeza concluída!"

help:
	@echo "Targets disponíveis:"
	@echo "  make compile    - Compila o projeto"
	@echo "  make simulate   - Executa simulação"
	@echo "  make wave       - Abre arquivo VCD em GTKWave"
	@echo "  make all        - Compila e simula"
	@echo "  make clean      - Remove arquivos gerados"
	@echo "  make help       - Mostra esta mensagem"

.PHONY: all compile simulate wave clean help
