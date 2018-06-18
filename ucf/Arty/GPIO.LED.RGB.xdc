## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##	Bank:						35
##		VCCO:					3.3V (FPGA_3V3)
##	Location:				LD0, LD1, LD2, LD3
## -----------------------------------------------------------------------------
## {OUT}	LD0.R;
set_property PACKAGE_PIN  G6        [ get_ports Arty_GPIO_LED[0]_R ]
## {OUT}	LD0.G;
set_property PACKAGE_PIN  F6        [ get_ports Arty_GPIO_LED[0]_G ]
## {OUT}	LD0.B;
set_property PACKAGE_PIN  E1        [ get_ports Arty_GPIO_LED[0]_B ]
## {OUT}	LD1.R;
set_property PACKAGE_PIN  G3        [ get_ports Arty_GPIO_LED[1]_R ]
## {OUT}	LD1.G;
set_property PACKAGE_PIN  J4        [ get_ports Arty_GPIO_LED[1]_G ]
## {OUT}	LD1.B;
set_property PACKAGE_PIN  G4        [ get_ports Arty_GPIO_LED[1]_B ]
## {OUT}	LD2.R;
set_property PACKAGE_PIN  J3        [ get_ports Arty_GPIO_LED[2]_R ]
## {OUT}	LD2.G;
set_property PACKAGE_PIN  J2        [ get_ports Arty_GPIO_LED[2]_G ]
## {OUT}	LD2.B;
set_property PACKAGE_PIN  H4        [ get_ports Arty_GPIO_LED[2]_B ]
## {OUT}	LD3.R;
set_property PACKAGE_PIN  K1        [ get_ports Arty_GPIO_LED[3]_R ]
## {OUT}	LD3.G;
set_property PACKAGE_PIN  H6        [ get_ports Arty_GPIO_LED[3]_G ]
## {OUT}	LD3.B;
set_property PACKAGE_PIN  K2        [ get_ports Arty_GPIO_LED[3]_B ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_GPIO_LED\[\d\]_[RGB]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_GPIO_LED\[\d\]_[RGB]} ]
