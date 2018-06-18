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
## Cursor Buttons
## -----------------------------------------------------------------------------
##  Bank:            14
##    VCCO:          3.3V (VCC3V3)
##  Location:        BTNU, BTNL, BTNC, BTNR, BTND
## -----------------------------------------------------------------------------
## {IN}    BTNU; high-active; external 10k pulldown resistor
set_property PACKAGE_PIN  M18       [ get_ports Nexys4DDR_GPIO_Button_North ]
## {IN}    BTNL; high-active; external 10k pulldown resistor
set_property PACKAGE_PIN  P17       [ get_ports Nexys4DDR_GPIO_Button_West ]
## {IN}    BTNC; high-active; external 10k pulldown resistor
set_property PACKAGE_PIN  N17       [ get_ports Nexys4DDR_GPIO_Button_Center ]
## {IN}    BTNR; high-active; external 10k pulldown resistor
set_property PACKAGE_PIN  M17       [ get_ports Nexys4DDR_GPIO_Button_East ]
## {IN}    BTND; high-active; external 10k pulldown resistor
set_property PACKAGE_PIN  P18       [ get_ports Nexys4DDR_GPIO_Button_South ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4DDR_GPIO_Button_.*} ]
# Ignore timings on async I/O pins
set_false_path                -from [ get_ports -regexp {Nexys4DDR_GPIO_Button_.*} ]
