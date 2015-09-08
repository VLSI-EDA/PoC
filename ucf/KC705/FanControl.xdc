## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Fan Control
## -----------------------------------------------------------------------------
##	Bank:						14, 15
##		VCCO:					2.5V, 2.5V (VCC2V5_FPGA, VCC2V5_FPGA)
##	Location:				J61, Q17 (NDT3055L)
## -----------------------------------------------------------------------------
## {OUT}		Q17.Gate; external 1k pullup resistor; Q17.Drain connects to J61.1 (GND)
set_property PACKAGE_PIN	L26				[get_ports KC705_FanControl_PWM]
## {IN}			J61.3; voltage limited by D15 (MM3Z2V7B; 2.7V zener-diode)
set_property PACKAGE_PIN	U22				[get_ports KC705_FanControl_Tacho]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {KC705_FanControl_.*}]
# Ignore timings on async I/O pins
set_false_path								-to		[get_ports KC705_FanControl_PWM]
set_false_path								-from	[get_ports KC705_FanControl_Tacho]
