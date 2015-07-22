## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Rotary-Button
## =============================================================================
##	Bank:						13
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				SW10
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN	AW31			[get_ports VC707_GPIO_Rotary_Button]			## SW10.5; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AR33			[get_ports VC707_GPIO_Rotary_IncA]				## SW10.1; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AT31			[get_ports VC707_GPIO_Rotary_IncB]				## SW10.6; high-active; external 4k7 pulldown resistor
set_property IOSTANDARD		LVCMOS18	[get_ports -regexp {VC707_GPIO_Rotary_.*}]

# Ignore timings on async I/O pins
set_false_path -to		[get_ports -regexp {VC707_GPIO_Rotary_.*}]
