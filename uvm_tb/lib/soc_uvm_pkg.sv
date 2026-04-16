// UVM Package - Base for SoC Verification
// CVA6 Dual-Core SoC with ACE Coherency Test Environment

`include "uvm_macros.svh"

import uvm_pkg::*;

package soc_uvm_pkg;
    
    // Include all UVM components
    `include "uvm_tb/agents/ace_master_agent.sv"
    `include "uvm_tb/agents/ace_slave_agent.sv"
    `include "uvm_tb/agents/memory_agent.sv"
    
    `include "uvm_tb/monitors/ace_monitor.sv"
    `include "uvm_tb/monitors/coherency_monitor.sv"
    
    `include "uvm_tb/sequences/ace_sequences.sv"
    `include "uvm_tb/sequences/coherency_sequences.sv"
    
    `include "uvm_tb/scoreboards/coherency_sb.sv"
    
    `include "uvm_tb/env/soc_env.sv"
    `include "uvm_tb/env/soc_virtual_sequencer.sv"
    
endpackage
