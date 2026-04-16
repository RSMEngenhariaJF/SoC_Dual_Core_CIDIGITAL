// Compilation file list for UVM testbench
// Include this in your simulator compilation

// RTL files
../../rtl/axi4/axi4_defines.sv
../../rtl/ace/ace_bus.sv

// UVM Package
lib/soc_uvm_pkg.sv

// Agents
agents/ace_master_agent.sv
agents/ace_slave_agent.sv
agents/memory_agent.sv

// Monitors
monitors/ace_monitor.sv
monitors/coherency_monitor.sv

// Sequences
sequences/ace_sequences.sv
sequences/coherency_sequences.sv

// Scoreboards
scoreboards/coherency_sb.sv

// Environment
env/soc_env.sv
env/soc_virtual_sequencer.sv

// Tests
tests/soc_tests.sv

// Testbench
tb_soc_uvm.sv
