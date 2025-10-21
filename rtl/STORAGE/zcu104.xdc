set_property PACKAGE_PIN AJ10 [get_ports clk]
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
