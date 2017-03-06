## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Special Buttons
## -----------------------------------------------------------------------------
##	Bank:						34
##		VCCO:					1.5V (FPGA_1V5)
##	Location:				SW8
## -----------------------------------------------------------------------------
## {IN}		SW8; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	U4				[get_ports AC701_GPIO_Button_CPU_Reset]
# set I/O standard
set_property IOSTANDARD		LVCMOS15	[get_ports AC701_GPIO_Button_CPU_Reset]
# Ignore timings on async I/O pins
set_false_path								-from [get_ports AC701_GPIO_Button_CPU_Reset]
