set_property PACKAGE_PIN AH11 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]
create_clock -period 3.000 -name clk -waveform {0.000 1.500} [get_ports clk]
