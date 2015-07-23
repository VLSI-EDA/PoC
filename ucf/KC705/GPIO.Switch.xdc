## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## DIP-Switches
## -----------------------------------------------------------------------------
##	Bank:						13
##		VCCO:					2.5V (VADJ_FPGA)
##	Location:				SW11
## -----------------------------------------------------------------------------
## {IN}		SW11.4; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	Y29				[get_ports KC705_GPIO_Switches[0]]
## {IN}		SW11.3; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	W29				[get_ports KC705_GPIO_Switches[1]]
## {IN}		SW11.2; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AA28			[get_ports KC705_GPIO_Switches[2]]
## {IN}		SW11.1; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	Y28				[get_ports KC705_GPIO_Switches[3]]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {KC705_GPIO_Switches\[\d\]}]
# Ignore timings on async I/O pins
set_false_path								-from [get_ports -regexp {KC705_GPIO_Switches\[\d\]}]
