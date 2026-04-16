// UVM Testbench for CVA6 Dual-Core SoC with ACE Coherency

`include "uvm_macros.svh"

import uvm_pkg::*;
import soc_uvm_pkg::*;

`include "uvm_tb/lib/soc_uvm_pkg.sv"
`include "uvm_tb/tests/soc_tests.sv"

module tb_soc_uvm;

    `include "rtl/axi4/axi4_defines.sv"
    
    logic                        clk;
    logic                        rst_n;
    
    // ACE Bus Interfaces
    ace_bus arch_bus (.clk(clk), .rst_n(rst_n));
    ace_bus core0_bus (.clk(clk), .rst_n(rst_n));
    ace_bus core1_bus (.clk(clk), .rst_n(rst_n));
    ace_bus mem_bus (.clk(clk), .rst_n(rst_n));
    
    // ===== Clock Generation =====
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // 100 MHz
    end
    
    // ===== Reset Generation =====
    initial begin
        rst_n = 1'b0;
        #15 rst_n = 1'b1;
    end
    
    // ===== DUT Instantiation =====
    soc_top #(
        .AXI_ID_WIDTH(4),
        .AXI_ADDR_WIDTH(32),
        .AXI_DATA_WIDTH(64),
        .AXI_USER_WIDTH(4)
    ) dut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mem_clk(),
        .mem_rst_n(),
        .mem_addr(),
        .mem_valid(),
        .mem_data(64'h0),
        .mem_ready(1'b1),
        .core0_pc(),
        .core0_valid(),
        .core1_pc(),
        .core1_valid(),
        .instr_counter(),
        .cycle_counter()
    );
    
    // ===== UVM Configuration =====
    initial begin
        // Set virtual interfaces
        uvm_config_db #(virtual ace_bus)::set(null, "uvm_test_top.env.core_agent_0", "ace_vif", core0_bus);
        uvm_config_db #(virtual ace_bus)::set(null, "uvm_test_top.env.core_agent_1", "ace_vif", core1_bus);
        uvm_config_db #(virtual ace_bus)::set(null, "uvm_test_top.env.slave_agent_0", "ace_vif", core0_bus);
        uvm_config_db #(virtual ace_bus)::set(null, "uvm_test_top.env.slave_agent_1", "ace_vif", core1_bus);
        uvm_config_db #(virtual ace_bus)::set(null, "uvm_test_top.env.mem_agent", "mem_vif", mem_bus);
        uvm_config_db #(virtual ace_bus)::set(null, "uvm_test_top.env.ace_monitor_0", "ace_vif", core0_bus);
        uvm_config_db #(virtual ace_bus)::set(null, "uvm_test_top.env.ace_monitor_1", "ace_vif", core1_bus);
        
        // Run test
        run_test();
    end
    
    // ===== Waveform Dump =====
    initial begin
        if ($test$plusargs("dump_vcd")) begin
            $dumpfile("uvm_sim.vcd");
            $dumpvars(0, tb_soc_uvm);
        end
    end
    
    // ===== Timeout =====
    initial begin
        #100us;
        $display("\n*** Simulation Timeout - 100us ***\n");
        $finish;
    end

endmodule
