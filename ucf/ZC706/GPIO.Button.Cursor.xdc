## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Cursor Buttons
## -----------------------------------------------------------------------------
##	Bank:						11, 35, 13
##		VCCO:					2.5V, 1.5V, 2.5V (VADJ_FPGA, VCC1V5_FPGA, VADJ_FPGA)
##	Location:				SW7, SW9, SW8
## -----------------------------------------------------------------------------
## {IN}		SW7; high-active; external 4k7 pulldown resistor; Bank 11; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	AK25				[get_ports ZC706_GPIO_Button_Left]
## {IN}		SW9; high-active; external 4k7 pulldown resistor; Bank 35; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	K15				[get_ports ZC706_GPIO_Button_Center]
## {IN}		SW8; high-active; external 4k7 pulldown resistor; Bank 13; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	R27				[get_ports ZC706_GPIO_Button_Right]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {ZC706_GPIO_Button_Left}]
set_property IOSTANDARD		LVCMOS15	[get_ports -regexp {ZC706_GPIO_Button_Center}]
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {ZC706_GPIO_Button_Right}]
# Ignore timings on async I/O pins
set_false_path								-from [get_ports -regexp {ZC706_GPIO_Button_.*}]
