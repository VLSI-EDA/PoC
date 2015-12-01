## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Special Buttons
## -----------------------------------------------------------------------------
##	Bank:						34
##		VCCO:					1.5V (VCC1V5_FPGA)
##	Location:				SW13
## -----------------------------------------------------------------------------
## {IN}		SW13; high-active; external 1k pulldown resistor
set_property PACKAGE_PIN	A8				[get_ports ZC706_GPIO_Button_CPU_Reset]
# set I/O standard
set_property IOSTANDARD		LVCMOS15	[get_ports ZC706_GPIO_Button_CPU_Reset]
# Ignore timings on async I/O pins
set_false_path								-from [get_ports ZC706_GPIO_Button_CPU_Reset]
