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
## RGB LEDs
## -----------------------------------------------------------------------------
##  Bank:            CONFIG, 15, 34, 35
##    VCCO:          3.3V (VCC3V3)
##  Location:        LD16, LD17
## -----------------------------------------------------------------------------
## {OUT}  LD16 - Red; Bank 34
set_property PACKAGE_PIN  K5        [ get_ports Nexys4_GPIO_LED_RGB_R[0] ]
## {OUT}  LD16 - Green; Bank 35
set_property PACKAGE_PIN  F13       [ get_ports Nexys4_GPIO_LED_RGB_G[0] ]
## {OUT}  LD16 - Blue; Bank 35
set_property PACKAGE_PIN  F6        [ get_ports Nexys4_GPIO_LED_RGB_B[0] ]

## {OUT}  LD17 - Red; Bank 34
set_property PACKAGE_PIN  K6        [ get_ports Nexys4_GPIO_LED_RGB_R[1] ]
## {OUT}  LD17 - Green; Bank 35
set_property PACKAGE_PIN  H6        [ get_ports Nexys4_GPIO_LED_RGB_G[1] ]
## {OUT}  LD17 - Blue; CONFIG
set_property PACKAGE_PIN  L16       [ get_ports Nexys4_GPIO_LED_RGB_B[1] ]


# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4_GPIO_LED_RGB_\w\[\d+\]} ]
# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Nexys4_GPIO_LED_RGB_\w\[\d+\]} ]
