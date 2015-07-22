## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## DIP-Switches
## =============================================================================
##	Bank:						13
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				SW2
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN	AV30		[get_ports VC707_GPIO_Switches[0]]					## SW2.1; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AY33		[get_ports VC707_GPIO_Switches[1]]					## SW2.2; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	BA31		[get_ports VC707_GPIO_Switches[2]]					## SW2.3; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	BA32		[get_ports VC707_GPIO_Switches[3]]					## SW2.4; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AW30		[get_ports VC707_GPIO_Switches[4]]					## SW2.5; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AY30		[get_ports VC707_GPIO_Switches[5]]					## SW2.6; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	BA30		[get_ports VC707_GPIO_Switches[6]]					## SW2.7; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	BB31		[get_ports VC707_GPIO_Switches[7]]					## SW2.8; high-active; external 4k7 pulldown resistor
set_property IOSTANDARD		LVCMOS18	[get_ports -regexp {VC707_GPIO_Switches\[\d\]}]

# Ignore timings on async I/O pins
set_false_path -to		[get_ports -regexp {VC707_GPIO_Switches\[\d\]}]
