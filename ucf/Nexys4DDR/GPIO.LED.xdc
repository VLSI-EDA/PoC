## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Nexys 4 DDR
## FPGA:          Xilinx Artix 7
##   Device:      XC7A100T
##   Package:     CSG324
##   Speedgrade:  -1
##
## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##  Bank:            CONFIG, 14, 15
##    VCCO:          3.3V (VCC3V3)
##  Location:        LD0..LD15
## -----------------------------------------------------------------------------
## {OUT}  LD0; Bank 15
set_property PACKAGE_PIN  H17       [ get_ports Nexys4DDR_GPIO_LED[0] ]
## {OUT}  LD1; Bank 15
set_property PACKAGE_PIN  K15       [ get_ports Nexys4DDR_GPIO_LED[1] ]
## {OUT}  LD2; Bank 15
set_property PACKAGE_PIN  J13       [ get_ports Nexys4DDR_GPIO_LED[2] ]
## {OUT}  LD3; Bank 14
set_property PACKAGE_PIN  N14       [ get_ports Nexys4DDR_GPIO_LED[3] ]
## {OUT}  LD4; Bank 14
set_property PACKAGE_PIN  R18       [ get_ports Nexys4DDR_GPIO_LED[4] ]
## {OUT}  LD5; Bank 14
set_property PACKAGE_PIN  V17       [ get_ports Nexys4DDR_GPIO_LED[5] ]
## {OUT}  LD6; Bank 14
set_property PACKAGE_PIN  U17       [ get_ports Nexys4DDR_GPIO_LED[6] ]
## {OUT}  LD7; Bank 14
set_property PACKAGE_PIN  U16       [ get_ports Nexys4DDR_GPIO_LED[7] ]
## {OUT}  LD8; Bank 14
set_property PACKAGE_PIN  V16       [ get_ports Nexys4DDR_GPIO_LED[8] ]
## {OUT}  LD9; Bank 14
set_property PACKAGE_PIN  T15       [ get_ports Nexys4DDR_GPIO_LED[9] ]
## {OUT}  LD10; Bank 14
set_property PACKAGE_PIN  U14       [ get_ports Nexys4DDR_GPIO_LED[10] ]
## {OUT}  LD11; Bank CONFIG
set_property PACKAGE_PIN  T16       [ get_ports Nexys4DDR_GPIO_LED[11] ]
## {OUT}  LD12; Bank CONFIG
set_property PACKAGE_PIN  V15       [ get_ports Nexys4DDR_GPIO_LED[12] ]
## {OUT}  LD13; Bank 14
set_property PACKAGE_PIN  V14       [ get_ports Nexys4DDR_GPIO_LED[13] ]
## {OUT}  LD14; Bank 14
set_property PACKAGE_PIN  V12       [ get_ports Nexys4DDR_GPIO_LED[14] ]
## {OUT}  LD15; Bank 14
set_property PACKAGE_PIN  V11       [ get_ports Nexys4DDR_GPIO_LED[15] ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4DDR_GPIO_LED\[\d+\]} ]
# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Nexys4DDR_GPIO_LED\[\d+\]} ]
