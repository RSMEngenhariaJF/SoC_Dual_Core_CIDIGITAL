# Vivado TCL Script
# CVA6 Dual-Core SoC with ACE Coherency
# Generated: 2026-04-08 23:31:05

# Create new project
create_project soc_dual_core_cva6 . -part {xc7z020clg484-1}

# Set project properties
set_property target_language SystemVerilog [current_project]
set_property default_lib xil_defaultlib [current_project]

# Add RTL files
add_files -norecurse rtl/axi4/axi4_defines.sv
add_files -norecurse rtl/ace/ace_bus.sv
add_files -norecurse rtl/cores/cva6_wrapper.sv
add_files -norecurse rtl/ccu/ccu.sv
add_files -norecurse rtl/llc/llc.sv
add_files -norecurse rtl/top/soc_top.sv

# Add Testbench files
add_files -norecurse -fileset sim_1 \
  tb/tb_soc_top.sv \


# Set simulation properties
set_property -name {xsim.simulate.runtime} -value {100us} -objects [get_filesets sim_1]
set_property top tb_soc_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Launch simulation
launch_simulation -simset sim_1 -mode behavioral

puts "Project soc_dual_core_cva6 created successfully!"
