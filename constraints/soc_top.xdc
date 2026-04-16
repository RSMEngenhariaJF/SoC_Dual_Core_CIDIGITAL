# XDC Constraints
# CVA6 Dual-Core SoC with ACE Coherency
# Generated: 2026-04-08 23:31:05

# Clock constraints
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_clock_groups -asynchronous -group {clk}

# Reset constraints
set_property PULLDOWN TRUE [get_ports rst_n]

# IO Timing
set_input_delay -clock clk 2.000 [get_ports {irq}]
set_output_delay -clock clk 2.000 [get_ports {mem_valid mem_addr}]

# Bank voltage
set_property IOSTANDARD LVCMOS33 [get_ports *]
set_property SLEW FAST [get_ports {mem_clk mem_rst_n mem_valid mem_addr[*]}]

