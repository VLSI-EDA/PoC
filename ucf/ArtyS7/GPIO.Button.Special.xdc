## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Special Buttons
## -----------------------------------------------------------------------------
##	Bank:						35
##		VCCO:					3.3V (VCC3V3)
##	Location:				BTNR
## -----------------------------------------------------------------------------
## {IN}		BTNR; low-active; external 10k pullup resistor
set_property PACKAGE_PIN  C18       [ get_ports ArtyS7_GPIO_Button_CPU_Reset ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports ArtyS7_GPIO_Button_CPU_Reset ]
# Ignore timings on async I/O pins
set_false_path								-from [ get_ports ArtyS7_GPIO_Button_CPU_Reset ]
