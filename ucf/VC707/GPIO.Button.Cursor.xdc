## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Cursor Buttons
## =============================================================================
##	Bank:						15
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				SW3, SW4, SW5, SW6, SW7
## -----------------------------------------------------------------------------
## SW 3; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AR40			[get_ports VC707_GPIO_Button_North]
## SW 7; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AW40			[get_ports VC707_GPIO_Button_West]
## SW 6; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AV39			[get_ports VC707_GPIO_Button_Center]
## SW 4; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AU38			[get_ports VC707_GPIO_Button_East]
## SW 5; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AP40			[get_ports VC707_GPIO_Button_South]
# set I/O standard
set_property IOSTANDARD		LVCMOS18	[get_ports -regexp {VC707_GPIO_Button_.*}]
# Ignore timings on async I/O pins
set_false_path								-from [get_ports -regexp {VC707_GPIO_Button_.*}]
