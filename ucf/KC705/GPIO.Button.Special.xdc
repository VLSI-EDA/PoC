## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Special Buttons
## -----------------------------------------------------------------------------
##	Bank:						34
##		VCCO:					1.5V (VCC1V5_FPGA)
##	Location:				SW7
## -----------------------------------------------------------------------------
## {IN}		SW7; high-active; external 4k7 pulldown resistor
set_property PACKAGE_PIN	AB7				[get_ports KC705_GPIO_Button_CPU_Reset]
# set I/O standard
set_property IOSTANDARD		LVCMOS15	[get_ports KC705_GPIO_Button_CPU_Reset]
# Ignore timings on async I/O pins
set_false_path								-from [get_ports KC705_GPIO_Button_CPU_Reset]
