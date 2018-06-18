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
## Cursor Buttons
## -----------------------------------------------------------------------------
##  Bank:            CONFIG, 14, 15
##    VCCO:          3.3V (VCC3V3)
##  Location:        BTNU, BTNL, BTNC, BTNR, BTND
## -----------------------------------------------------------------------------
## {IN}    BTNU; high-active; external 10k pulldown resistor; Bank 15
set_property PACKAGE_PIN  F15       [ get_ports Nexys4_GPIO_Button_North ]
## {IN}    BTNL; high-active; external 10k pulldown resistor; Bank CONFIG
set_property PACKAGE_PIN  T16       [ get_ports Nexys4_GPIO_Button_West ]
## {IN}    BTNC; high-active; external 10k pulldown resistor; Bank 15
set_property PACKAGE_PIN  E16       [ get_ports Nexys4_GPIO_Button_Center ]
## {IN}    BTNR; high-active; external 10k pulldown resistor; Bank 14
set_property PACKAGE_PIN  R10       [ get_ports Nexys4_GPIO_Button_East ]
## {IN}    BTND; high-active; external 10k pulldown resistor; Bank 14
set_property PACKAGE_PIN  V10       [ get_ports Nexys4_GPIO_Button_South ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4_GPIO_Button_.*} ]
# Ignore timings on async I/O pins
set_false_path                -from [ get_ports -regexp {Nexys4_GPIO_Button_.*} ]
