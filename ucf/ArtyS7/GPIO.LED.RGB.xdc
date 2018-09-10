## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##	Bank:						15
##		VCCO:					3.3V (FPGA_3V3)
##	Location:				LD0, LD1
## -----------------------------------------------------------------------------
## {OUT}	LD0.R;
set_property PACKAGE_PIN  J15       [ get_ports "ArtyS7_GPIO_LED[0][R]" ]
## {OUT}	LD0.G;
set_property PACKAGE_PIN  G17       [ get_ports "ArtyS7_GPIO_LED[0][G]" ]
## {OUT}	LD0.B;
set_property PACKAGE_PIN  F15       [ get_ports "ArtyS7_GPIO_LED[0][B]" ]
## {OUT}	LD1.R;
set_property PACKAGE_PIN  E15       [ get_ports "ArtyS7_GPIO_LED[1][R]" ]
## {OUT}	LD1.G;
set_property PACKAGE_PIN  F18       [ get_ports "ArtyS7_GPIO_LED[1][G]" ]
## {OUT}	LD1.B;
set_property PACKAGE_PIN  E14       [ get_ports "ArtyS7_GPIO_LED[1][B]" ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyS7_GPIO_LED\[\d\]\[[RGB]\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {ArtyS7_GPIO_LED\[\d\]\[[RGB]\]} ]
