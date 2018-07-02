## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##	Bank:					35, 14
##	VCCO:					3.3V (FPGA_3V3)
##	Location:				LD4, LD5, LD6, LD7
## -----------------------------------------------------------------------------
## {OUT}	LD4;
set_property PACKAGE_PIN  H5        [ get_ports Arty_GPIO_LED[4] ]
## {OUT}	LD5;
set_property PACKAGE_PIN  J5        [ get_ports Arty_GPIO_LED[5] ]
## {OUT}	LD6;
set_property PACKAGE_PIN  T9        [ get_ports Arty_GPIO_LED[6] ]
## {OUT}	LD7;
set_property PACKAGE_PIN  T10       [ get_ports Arty_GPIO_LED[7] ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_GPIO_LED\[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_GPIO_LED\[\d\]} ]
