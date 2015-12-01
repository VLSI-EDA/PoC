## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Fan Control
## -----------------------------------------------------------------------------
##	Bank:						9
##		VCCO:					2.5V (VADJ_FPGA)
##	Location:				J61, Q1 (NDT3055L)
## -----------------------------------------------------------------------------
## {OUT}		Q1.Gate; external 1k pullup resistor; Q1.Drain connects to J61.1 (GND)
set_property PACKAGE_PIN	AB19				[get_ports ZC706_FanControl_PWM]
## {IN}			J61.3; voltage limited by D2 (MM3Z2V7B; 2.7V zener-diode)
set_property PACKAGE_PIN	AA19				[get_ports ZC706_FanControl_Tacho]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {ZC706_FanControl_.*}]
# Ignore timings on async I/O pins
set_false_path								-to		[get_ports ZC706_FanControl_PWM]
set_false_path								-from	[get_ports ZC706_FanControl_Tacho]
