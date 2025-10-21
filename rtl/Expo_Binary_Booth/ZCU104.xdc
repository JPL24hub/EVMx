set_property PACKAGE_PIN AJ10 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]
create_clock -period 2.000 -name clk -waveform {0.000 1.000} [get_ports clk]
