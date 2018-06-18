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
## RGB LEDs
## -----------------------------------------------------------------------------
##  Bank:            14, 15
##    VCCO:          3.3V (VCC3V3)
##  Location:        LD16, LD17
## -----------------------------------------------------------------------------
## {OUT}  LD16 - Red; Bank 14
set_property PACKAGE_PIN  N15       [ get_ports Nexys4DDR_GPIO_LED_RGB_R[0] ]
## {OUT}  LD16 - Green; Bank 14
set_property PACKAGE_PIN  M16       [ get_ports Nexys4DDR_GPIO_LED_RGB_G[0] ]
## {OUT}  LD16 - Blue; Bank 14
set_property PACKAGE_PIN  R12       [ get_ports Nexys4DDR_GPIO_LED_RGB_B[0] ]

## {OUT}  LD17 - Red; Bank 14
set_property PACKAGE_PIN  N16       [ get_ports Nexys4DDR_GPIO_LED_RGB_R[1] ]
## {OUT}  LD17 - Green; Bank 14
set_property PACKAGE_PIN  R11       [ get_ports Nexys4DDR_GPIO_LED_RGB_G[1] ]
## {OUT}  LD17 - Blue; Bank 15
set_property PACKAGE_PIN  G14       [ get_ports Nexys4DDR_GPIO_LED_RGB_B[1] ]


# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4DDR_GPIO_LED_RGB_\w\[\d+\]} ]
# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Nexys4DDR_GPIO_LED_RGB_\w\[\d+\]} ]
