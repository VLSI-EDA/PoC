##
## Fan Control
## =============================================================================
##	Bank:						15
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				J48, Q1
## -----------------------------------------------------------------------------
## Q1.Gate; external 1k pullup resistor
set_property PACKAGE_PIN	BA37			[get_ports VC707_FanControl_PWM]
## J48 - Pin 3; voltage limited by D2 (DDZ9678 - 1.8V zener-diode)
set_property PACKAGE_PIN	BB37			[get_ports VC707_FanControl_Tacho]
# set I/O standard
set_property IOSTANDARD		LVCMOS18	[get_ports -regexp {VC707_FanControl_.*}]
# Ignore timings on async I/O pins
#set_false_path								-to		[get_ports VC707_FanControl_PWM]
set_false_path								-from	[get_ports VC707_FanControl_Tacho]
