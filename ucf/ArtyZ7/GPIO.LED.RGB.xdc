## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyZ7
## FPGA:          Xilinx Zynq 7
## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
## LEDs (RGB)
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:				35
##	VCCO:				VCC5V0	
##	Location:			LD4, LD5, 
## -----------------------------------------------------------------------------

## {OUT}	LD4.R;
set_property PACKAGE_PIN  N15       [ get_ports ArtyZ7_GPIO_LED[4]_R ]
## {OUT}	LD4.G;
set_property PACKAGE_PIN  G17       [ get_ports ArtyZ7_GPIO_LED[4]_G ]
## {OUT}	LD4.B;
set_property PACKAGE_PIN  L15       [ get_ports ArtyZ7_GPIO_LED[4]_B ]
## {OUT}	LD5.R;
set_property PACKAGE_PIN  M15       [ get_ports ArtyZ7_GPIO_LED[5]_R ]
## {OUT}	LD5.G;
set_property PACKAGE_PIN  L14       [ get_ports ArtyZ7_GPIO_LED[5]_G ]
## {OUT}	LD5.B;
set_property PACKAGE_PIN  G14       [ get_ports ArtyZ7_GPIO_LED[5]_B ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyZ7_GPIO_LED\[\d\]_[RGB]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {ArtyZ7_GPIO_LED\[\d\]_[RGB]} ]
