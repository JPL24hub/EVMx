set_property IOSTANDARD LVCMOS18 [get_ports clk]
set_property PACKAGE_PIN AH12 [get_ports clk]
create_clock -period 7.000 -name clk -waveform {0.000 3.500} [get_ports clk]


set_property PACKAGE_PIN W4 [get_ports clk]
