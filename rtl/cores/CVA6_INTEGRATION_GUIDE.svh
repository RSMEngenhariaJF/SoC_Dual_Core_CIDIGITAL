// CVA6 Integration Guide - Real CVA6 RISC-V Core
// This file explains the complete CLV6 integration for the ACE SoC

/*
=================================================================================
CVA6 FULL INTEGRATION - HOW TO GET THE REAL CORE
=================================================================================

The current cva6_wrapper.sv is a BEHAVIORAL MODEL ONLY.

To integrate the REAL CVA6 core, follow these steps:

1. CLONE THE CVA6 REPOSITORY
   
   git clone https://github.com/openhwgroup/cva6.git cva6_repo
   cd cva6_repo
   git checkout master  # or specific tag/branch

2. CVA6 DIRECTORY STRUCTURE

   cva6_repo/
   ├── corev_apu/                    # Main RTL
   │   ├── apu/                      # FPU (Floating Point)
   │   ├── bootrom/                  # Boot ROM
   │   ├── clint/                    # Core Local Interruptor
   │   ├── debug/                    # Debug module
   │   ├── fpu/                      # Floating point unit
   │   ├── frontend/                 # Instruction fetch/decode
   │   │   ├── bht.sv                # Branch history table
   │   │   ├── instr_queue.sv        # Instruction queue
   │   │   └── icache.sv             # Instruction cache
   │   ├── memory_subsystem/         # Caches and memory
   │   │   ├── dcache/               # Data cache
   │   │   │   ├── dcache.sv
   │   │   │   ├── controller.sv
   │   │   │   └── wt_dcache.sv
   │   │   └── wt_cache_subsystem/   # Write-through cache
   │   ├── lsu/                      # Load-Store Unit
   │   │   ├── lsu.sv
   │   │   ├── misaligned.sv
   │   │   └── pma.sv
   │   ├── cache_subsystem/
   │   ├── acc_unit/                 # Accelerator unit
   │   ├── alu.sv                    # Arithmetic Logic Unit
   │   ├── branch_unit.sv            # Branch execution
   │   ├── compressed_decoder.sv     # C extension decoder
   │   ├── controller.sv             # Main controller
   │   ├── csr_regfile.sv            # CSR registers
   │   ├── ex_stage.sv               # Execute stage
   │   ├── id_stage.sv               # Decode stage
   │   ├── if_stage.sv               # Fetch stage
   │   ├── instr_decoder.sv          # Instruction decoder
   │   ├── mult.sv                   # Multiplier
   │   ├── pmp.sv                    # Physical Memory Protection
   │   ├── register_file.sv          # GPR file
   │   └── cva6.sv                   # TOP LEVEL MODULE
   ├── testbench/
   ├── scripts/
   └── docs/

3. KEY CVA6 MODULES TO INTEGRATE

   Top Level: cva6.sv
   Input Ports:
   - clk_i                    # Clock
   - rst_ni                   # Reset (active low)
   - boot_addr_i[63:0]        # Boot address
   - hart_id_i[63:0]          # Hart ID
   - intr_i                   # Interrupt
   - debug_req_i              # Debug request
   
   AXI4 Master Interfaces:
   - axi_req_o                # AXI request
   - axi_resp_i               # AXI response
   
4. PARAMETER CONFIGURATION

   localparam bit PRIV_STAT_EN = 1'b0;     // Privilege mode
   localparam bit FPU_EN = 1'b0;            // FPU enable
   localparam bit FP_PRESENT = 1'b0;        // TBDPrecision present
   localparam bit NSX = 1'b0;               // Non-standard extensions

5. ACE INTERFACE ADAPTATION

   CVA6 native: AXI4 64-bit
   Target: AXI4 + ACE extensions
   
   Conversion needed:
   - AXI4 write bursts → ACE write transactions
   - Read bursts with snoop support
   - Add snoop response channels
   - Implement cache coherency signals

6. INTEGRATION STEPS

   Step 1: Copy CVA6 RTL files to rtl/cores/cva6/
   
           mkdir -p rtl/cores/cva6
           cp cva6_repo/corev_apu/cva6* rtl/cores/cva6/
           cp cva6_repo/corev_apu/<subsystems> rtl/cores/cva6/
   
   Step 2: Create ACE interface adapter
   
           New file: rtl/cores/cva6_ace_adapter.sv
           (Convert AXI4 to AXI4+ACE)
   
   Step 3: Replace cva6_wrapper.sv with real instantiation
   
           module cva6_core (
               input clk,
               input rst_n,
               ace_bus.master ace_if,
               input [63:0] boot_addr,
               input [63:0] hart_id,
               output [63:0] pc,
               output valid
           );
           
           // Real CVA6 instantiation
           cva6 #(...) i_cva6 (
               .clk_i(clk),
               .rst_ni(rst_n),
               .boot_addr_i(boot_addr),
               .hart_id_i(hart_id),
               .axi_req_o(axi4_req),
               .axi_resp_i(axi4_resp),
               ...
           );
           
           // Adaptation layer
           cva6_ace_adapter adapter (
               .axi4_req(axi4_req),
               .axi4_resp(axi4_resp),
               .ace_req(ace_if.aw/ar/w/...),
               .ace_resp(ace_if.b/r/...)
           );
           
           endmodule

7. BUILD WITH CVA6

   Make sure include paths point to CVA6:
   
   xvlog -sverilog \
       +incdir+cva6_repo/corev_apu \
       +incdir+rtl/cores/cva6 \
       rtl/cores/cva6/*.sv \
       rtl/...
   
   or in Vivado project:
   
   # TCL script
   set_property include_dirs {
       cva6_repo/corev_apu
       rtl/cores/cva6
   } [current_fileset]
   
   add_files {
       cva6_repo/corev_apu/cva6.sv
       cva6_repo/corev_apu/frontend/*.sv
       cva6_repo/corev_apu/execute_stage/*.sv
       cva6_repo/corev_apu/memory_subsystem/*.sv
       ...
   }

8. CVA6 FEATURES SUMMARY

   Architecture:      RISC-V RV64IMAC
   Stages:            6-stage pipeline (IF, ID, EX, MEM, WB, +special)
   Branch Prediction: Fully integrated
   Caches:            Configurable I-cache and D-cache
   MMU:               Optional TLB
   CSRs:              Full M-mode support
   Interrupts:        Supported
   Performance:       ~1.0 IPC @ 1GHz

9. EXPECTED PERFORMANCE WITH ACE

   - Read latency: ~5 cycles (cache hit)
   - Write latency: ~3 cycles
   - Cache size: 16KB I-cache + 16KB D-cache (configurable)
   - Snoop latency: ~4 cycles
   - Dual-core throughput: ~1.5-1.8 IPC combined

10. TESTING THE REAL CVA6

    Use CVA6 verification suite from cva6_repo/verif/
    
    UVM tests should work with real core:
    - read_test: Verify cache hits
    - write_test: Verify write-back operations
    - coherency_test: Verify snoop responses
    - stress_test: Full system stress

11. LIMITATIONS (If using wrapper for now)

    Current wrapper (cva6_wrapper.sv) provides:
    ✓ ACE interface
    ✓ Basic read/write transactions
    ✓ Mock snoop responses
    ✗ Real pipeline execution
    ✗ Branch prediction
    ✗ Cache operations
    ✗ CSR support
    
    To enable full functionality, replace with real CVA6.

12. NEXT STEPS

    A. Immediate (wrapper mode):
       - Use current environment for UVM verification development
       - Develop coherency verification framework
       - Test protocols and interfaces
    
    B. Production (real CVA6):
       - Clone CVA6 repository
       - Integrate with ACE adapter
       - Run full verification suite
       - Synthesize for FPGA/ASIC

=================================================================================
*/

`ifndef CVA6_INTEGRATION_GUIDE
`define CVA6_INTEGRATION_GUIDE

// Placeholder for documentation
module cva6_integration_placeholder;
endmodule

`endif
