set_property PACKAGE_PIN AH11 [get_ports clk]
create_clock -period 2.000 -name clk -waveform {0.000 1.000} [get_ports clk]
