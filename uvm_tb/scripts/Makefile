# Makefile for UVM Testbench
# CVA6 Dual-Core SoC with ACE Coherency

TOOL       = vcs
DUMP_VCD   = ""

# Directories
UVM_DIR    = .
SIM_DIR    = $(UVM_DIR)/sim
AGENTS_DIR = $(UVM_DIR)/agents
SEQS_DIR   = $(UVM_DIR)/sequences
TESTS_DIR  = $(UVM_DIR)/tests
MON_DIR    = $(UVM_DIR)/monitors
SB_DIR     = $(UVM_DIR)/scoreboards
ENV_DIR    = $(UVM_DIR)/env
LIB_DIR    = $(UVM_DIR)/lib
RTL_DIR    = ../../rtl

# Source files
RTL_FILES  = \
	$(RTL_DIR)/axi4/axi4_defines.sv \
	$(RTL_DIR)/ace/ace_bus.sv

AGENT_FILES = \
	$(AGENTS_DIR)/ace_master_agent.sv \
	$(AGENTS_DIR)/ace_slave_agent.sv \
	$(AGENTS_DIR)/memory_agent.sv

MON_FILES  = \
	$(MON_DIR)/ace_monitor.sv \
	$(MON_DIR)/coherency_monitor.sv

SEQ_FILES  = \
	$(SEQS_DIR)/ace_sequences.sv \
	$(SEQS_DIR)/coherency_sequences.sv

SB_FILES   = $(SB_DIR)/coherency_sb.sv

ENV_FILES  = \
	$(ENV_DIR)/soc_env.sv \
	$(ENV_DIR)/soc_virtual_sequencer.sv

TEST_FILES = $(TESTS_DIR)/soc_tests.sv

TB_FILE    = $(UVM_DIR)/tb_soc_uvm.sv

# Compile options
VCOMP_OPTS = -sverilog -nc \
	-timescale=1ns/1ps \
	+incdir+$(UVM_DIR) \
	+incdir+$(RTL_DIR) \
	+define+UVM_NO_DPI

# Available tests
TESTS      = base_test read_test write_test mixed_test coherency_test stress_test

# Default test
TEST       ?= base_test

SIMV       = $(SIM_DIR)/simv
WAVEFORM   = $(SIM_DIR)/uvm_sim.vcd

.PHONY: all compile simulate clean test_all help

all: compile simulate

# Create simulation directory
$(SIM_DIR):
	mkdir -p $@

# Compile
compile: $(SIM_DIR)
	@echo "======================================"
	@echo "Compiling UVM Testbench..."
	@echo "Test: $(TEST)"
	@echo "======================================"
	$(TOOL) $(VCOMP_OPTS) \
		$(RTL_FILES) \
		$(AGENT_FILES) \
		$(MON_FILES) \
		$(SEQ_FILES) \
		$(SB_FILES) \
		$(ENV_FILES) \
		$(TEST_FILES) \
		$(TB_FILE) \
		-top tb_soc_uvm \
		-o $(SIMV) && echo "✓ Compilation successful"

# Simulate
simulate:
	@echo "======================================"
	@echo "Running Simulation: $(TEST)"
	@echo "======================================"
	cd $(SIM_DIR) && \
	./simv +UVM_TESTNAME=$(TEST) \
	        +UVM_VERBOSITY=UVM_MEDIUM \
	        $(DUMP_VCD) && \
	echo "✓ Simulation successful"

# Generate waveforms
wave:
	@if [ -f "$(WAVEFORM)" ]; then \
		gtkwave $(WAVEFORM) &; \
		echo "Waveform viewer opened"; \
	else \
		echo "Error: $(WAVEFORM) not found"; \
	fi

# Test all available tests
test_all:
	@for test in $(TESTS); do \
		echo ""; \
		echo "Running: $$test"; \
		$(MAKE) TEST=$$test simulate; \
		if [ $$? -ne 0 ]; then \
			echo "✗ Test $$test FAILED"; \
		else \
			echo "✓ Test $$test PASSED"; \
		fi; \
	done

# Run single test with VCD dump
test_with_vcd:
	$(MAKE) DUMP_VCD="+dump_vcd" TEST=$(TEST) all

# Clean
clean:
	@echo "Cleaning simulation artifacts..."
	rm -rf $(SIM_DIR)
	rm -f csrc
	rm -f *.key
	rm -f *.fsdb
	rm -f DVEfiles
	@echo "✓ Clean complete"

# Help
help:
	@echo "======================================"
	@echo "UVM Testbench Makefile"
	@echo "======================================"
	@echo ""
	@echo "Available targets:"
	@echo "  make compile         - Compile testbench"
	@echo "  make simulate        - Run simulation"
	@echo "  make all             - Compile and simulate"
	@echo "  make wave            - View waveforms"
	@echo "  make test_all        - Run all tests"
	@echo "  make test_with_vcd   - Run with VCD dump"
	@echo "  make clean           - Remove artifacts"
	@echo "  make help            - Show this help"
	@echo ""
	@echo "Available tests:"
	@for test in $(TESTS); do echo "  $$test"; done
	@echo ""
	@echo "Examples:"
	@echo "  make TEST=read_test"
	@echo "  make TEST=coherency_test test_with_vcd"
	@echo "  make test_all"
	@echo "======================================"

