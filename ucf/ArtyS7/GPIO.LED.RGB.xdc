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
set_property PACKAGE_PIN  J15       [ get_ports ArtyS7_GPIO_LED[0]_R ]
## {OUT}	LD0.G;
set_property PACKAGE_PIN  G17       [ get_ports ArtyS7_GPIO_LED[0]_G ]
## {OUT}	LD0.B;
set_property PACKAGE_PIN  F15       [ get_ports ArtyS7_GPIO_LED[0]_B ]
## {OUT}	LD1.R;
set_property PACKAGE_PIN  E15       [ get_ports ArtyS7_GPIO_LED[1]_R ]
## {OUT}	LD1.G;
set_property PACKAGE_PIN  F18       [ get_ports ArtyS7_GPIO_LED[1]_G ]
## {OUT}	LD1.B;
set_property PACKAGE_PIN  E14       [ get_ports ArtyS7_GPIO_LED[1]_B ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyS7_GPIO_LED\[\d\]_[RGB]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {ArtyS7_GPIO_LED\[\d\]_[RGB]} ]
