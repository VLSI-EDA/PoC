## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##	Bank:						15
##		VCCO:					3.3V (FPGA_3V3)
##	Location:				LD2, LD3, LD4, LD5
## -----------------------------------------------------------------------------
## {OUT}	LD4;
set_property PACKAGE_PIN  E18       [ get_ports ArtyS7_GPIO_LED[2] ]
## {OUT}	LD5;
set_property PACKAGE_PIN  F13       [ get_ports ArtyS7_GPIO_LED[3] ]
## {OUT}	LD6;
set_property PACKAGE_PIN  E13       [ get_ports ArtyS7_GPIO_LED[4] ]
## {OUT}	LD7;
set_property PACKAGE_PIN  H15       [ get_ports ArtyS7_GPIO_LED[5] ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyS7_GPIO_LED\[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {ArtyS7_GPIO_LED\[\d\]} ]
