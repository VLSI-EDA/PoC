## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Special Buttons
## -----------------------------------------------------------------------------
##	Bank:					35
##	VCCO:					3.3V (VCC3V3)
##	Location:				BTNR
## -----------------------------------------------------------------------------
## {IN}		BTNR; low-active; external 10k pullup resistor
set_property PACKAGE_PIN  C2        [ get_ports Arty_GPIO_Button_CPU_Reset_n ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports Arty_GPIO_Button_CPU_Reset_n ]
# Ignore timings on async I/O pins
set_false_path						-from [ get_ports Arty_GPIO_Button_CPU_Reset_n ]
