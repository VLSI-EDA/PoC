## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Nexys 4
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
##  Bank:            34
##    VCCO:          3.3V (VCC3V3)
##  Location:        LD0..LD15
## -----------------------------------------------------------------------------
## {OUT}  LD0
set_property PACKAGE_PIN  T8        [ get_ports Nexys4_GPIO_LED[0] ]
## {OUT}  LD1
set_property PACKAGE_PIN  V9        [ get_ports Nexys4_GPIO_LED[1] ]
## {OUT}  LD2
set_property PACKAGE_PIN  R8        [ get_ports Nexys4_GPIO_LED[2] ]
## {OUT}  LD3
set_property PACKAGE_PIN  T6        [ get_ports Nexys4_GPIO_LED[3] ]
## {OUT}  LD4
set_property PACKAGE_PIN  T5        [ get_ports Nexys4_GPIO_LED[4] ]
## {OUT}  LD5
set_property PACKAGE_PIN  T4        [ get_ports Nexys4_GPIO_LED[5] ]
## {OUT}  LD6
set_property PACKAGE_PIN  U7        [ get_ports Nexys4_GPIO_LED[6] ]
## {OUT}  LD7
set_property PACKAGE_PIN  U6        [ get_ports Nexys4_GPIO_LED[7] ]
## {OUT}  LD8
set_property PACKAGE_PIN  V4        [ get_ports Nexys4_GPIO_LED[8] ]
## {OUT}  LD9
set_property PACKAGE_PIN  U3        [ get_ports Nexys4_GPIO_LED[9] ]
## {OUT}  LD10
set_property PACKAGE_PIN  V1        [ get_ports Nexys4_GPIO_LED[10] ]
## {OUT}  LD11
set_property PACKAGE_PIN  R1        [ get_ports Nexys4_GPIO_LED[11] ]
## {OUT}  LD12
set_property PACKAGE_PIN  P5        [ get_ports Nexys4_GPIO_LED[12] ]
## {OUT}  LD13
set_property PACKAGE_PIN  U1        [ get_ports Nexys4_GPIO_LED[13] ]
## {OUT}  LD14
set_property PACKAGE_PIN  R2        [ get_ports Nexys4_GPIO_LED[14] ]
## {OUT}  LD15
set_property PACKAGE_PIN  P2        [ get_ports Nexys4_GPIO_LED[15] ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4_GPIO_LED\[\d+\]} ]
# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Nexys4_GPIO_LED\[\d+\]} ]
