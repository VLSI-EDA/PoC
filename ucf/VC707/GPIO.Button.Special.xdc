## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Special Buttons
## =============================================================================
##	Bank:						15
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				SW8
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN	AV40			[get_ports VC707_GPIO_Button_CPU_Reset]			## high-active; external 4k7 pulldown resistor
set_property IOSTANDARD		LVCMOS18	[get_ports VC707_GPIO_Button_CPU_Reset]

# Ignore timings on async I/O pins
set_false_path -to [get_ports VC707_GPIO_Button_CPU_Reset]
