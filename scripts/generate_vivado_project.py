#!/usr/bin/env python3
"""
Vivado Build Script for CVA6 Dual-Core SoC with ACE Coherency
Generates project configuration and build files for Xilinx Vivado
"""

import os
import sys
from pathlib import Path
from datetime import datetime

class VivadoProjectGenerator:
    def __init__(self, project_name, project_path):
        self.project_name = project_name
        self.project_path = Path(project_path)
        self.timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    def generate_tcl_script(self):
        """Generate Vivado TCL script for project creation"""
        
        rtl_files = [
            "rtl/axi4/axi4_defines.sv",
            "rtl/ace/ace_bus.sv",
            "rtl/cores/cva6_wrapper.sv",
            "rtl/ccu/ccu.sv",
            "rtl/llc/llc.sv",
            "rtl/top/soc_top.sv",
        ]
        
        tb_files = [
            "tb/tb_soc_top.sv",
        ]
        
        tcl_content = f"""# Vivado TCL Script
# CVA6 Dual-Core SoC with ACE Coherency
# Generated: {self.timestamp}

# Create new project
create_project {self.project_name} . -part {{xc7z020clg484-1}}

# Set project properties
set_property target_language SystemVerilog [current_project]
set_property default_lib xil_defaultlib [current_project]

# Add RTL files
"""
        
        for rtl_file in rtl_files:
            tcl_content += f"add_files -norecurse {rtl_file}\n"
        
        tcl_content += "\n# Add Testbench files\n"
        tcl_content += "add_files -norecurse -fileset sim_1 \\\n"
        for tb_file in tb_files:
            tcl_content += f"  {tb_file} \\\n"
        
        tcl_content += f"""

# Set simulation properties
set_property -name {{xsim.simulate.runtime}} -value {{100us}} -objects [get_filesets sim_1]
set_property top tb_soc_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Launch simulation
launch_simulation -simset sim_1 -mode behavioral

puts "Project {self.project_name} created successfully!"
"""
        
        return tcl_content
    
    def generate_xdc_constraints(self):
        """Generate XDC constraints file"""
        
        xdc_content = f"""# XDC Constraints
# CVA6 Dual-Core SoC with ACE Coherency
# Generated: {self.timestamp}

# Clock constraints
create_clock -period 10.000 -name clk -waveform {{0.000 5.000}} [get_ports clk]
set_clock_groups -asynchronous -group {{clk}}

# Reset constraints
set_property PULLDOWN TRUE [get_ports rst_n]

# IO Timing
set_input_delay -clock clk 2.000 [get_ports {{irq}}]
set_output_delay -clock clk 2.000 [get_ports {{mem_valid mem_addr}}]

# Bank voltage
set_property IOSTANDARD LVCMOS33 [get_ports *]
set_property SLEW FAST [get_ports {{mem_clk mem_rst_n mem_valid mem_addr[*]}}]

"""
        
        return xdc_content
    
    def generate_build_info(self):
        """Generate build information file"""
        
        build_info = f"""# Build Information
# CVA6 Dual-Core SoC with ACE Coherency
# Generated: {self.timestamp}

## Project Configuration
- Project Name: {self.project_name}
- Project Path: {self.project_path}
- Target Device: Xilinx Zynq-7000 (xc7z020clg484-1)
- HDL Language: SystemVerilog (2017)

## Source Files
### RTL Files (1379 lines total)
- rtl/axi4/axi4_defines.sv        (58 lines)  - AXI4 Protocol Definitions
- rtl/ace/ace_bus.sv              (141 lines) - ACE Bus Interface
- rtl/cores/cva6_wrapper.sv       (177 lines) - CVA6 Processor Wrapper
- rtl/ccu/ccu.sv                  (300 lines) - Cache Coherency Unit
- rtl/llc/llc.sv                  (335 lines) - Last Level Cache
- rtl/top/soc_top.sv              (163 lines) - SoC Top-Level

### Testbench Files (141 lines)
- tb/tb_soc_top.sv                          - Comprehensive Testbench

## Simulation Configuration
- Top Module: tb_soc_top
- Simulation Time: 100 µs
- Clock Period: 10 ns (100 MHz)
- Reset: Active low

## Architecture Overview
### Cores (2x)
- CVA6 RISC-V Processor
- 64-bit architecture
- AXI4 + ACE Master Interface
- Instruction & Data caches

### Coherency
- Cache Coherency Unit (CCU)
  - Priority arbitration (Core 0 > Core 1)
  - Snoop broadcast mechanism
  - Transaction routing

- Last Level Cache (LLC)
  - Shared L2: 4 KB
  - 4-way associative
  - 64-byte cache lines
  - MOESI protocol support

### Interfaces
- ACE (AMBA AXI4 Coherency Extensions)
- External AXI4 for DDR access
- Snoop broadcasts (AC, CR, CD channels)

## Performance Metrics
- IPC (Instructions Per Cycle): Target > 0.5 per core
- Cache Hit Rate: Expected > 95% (L2)
- Memory Latency: ~50 ns (external)

## Next Steps
1. Open Vivado: vivado {self.project_name}.xpr
2. Run synthesis: synth_design -top soc_top
3. Place & Route: impl_design
4. Generate Bitstream: write_bitstream soc_top.bit

## Build Commands
```bash
# Window/PowerShell with Vivado installed
vivado -mode batch -source scripts/build.tcl

# Linux/macOS
vivado -mode batch -source scripts/build.tcl

# Simulation only (no synthesis)
vivado -mode batch -source scripts/simulate.tcl
```

## Known Limitations
- CVA6 wrapper is behavioral (full RTL integration required)
- Memory model supports up to 128 KB
- No dynamic frequency scaling
- Single coherency domain (SYS_SHARED)

## Contacts & References
- CVA6 Repository: https://github.com/openhwgroup/cva6
- ACE Specification: https://developer.arm.com/documentation/
- Vivado Documentation: https://docs.xilinx.com/
"""
        
        return build_info


def main():
    generator = VivadoProjectGenerator(
        "soc_dual_core_cva6",
        "."
    )
    
    print("Generating Vivado Project Files...")
    print()
    
    # Generate TCL script
    tcl_script = generator.generate_tcl_script()
    tcl_path = Path("scripts/create_project.tcl")
    tcl_path.parent.mkdir(parents=True, exist_ok=True)
    tcl_path.write_text(tcl_script)
    print(f"✓ Generated: {tcl_path}")
    
    # Generate XDC constraints
    xdc_constraints = generator.generate_xdc_constraints()
    xdc_path = Path("constraints/soc_top.xdc")
    xdc_path.parent.mkdir(parents=True, exist_ok=True)
    xdc_path.write_text(xdc_constraints)
    print(f"✓ Generated: {xdc_path}")
    
    # Generate build info
    build_info = generator.generate_build_info()
    info_path = Path("docs/BUILD_INFO.md")
    info_path.parent.mkdir(parents=True, exist_ok=True)
    info_path.write_text(build_info)
    print(f"✓ Generated: {info_path}")
    
    print()
    print("✓ All project files generated successfully!")
    print()
    print("To use these files:")
    print("  1. Open Vivado")
    print(f"  2. Source: scripts/create_project.tcl")
    print("  3. Run simulation or synthesis")

if __name__ == "__main__":
    main()
