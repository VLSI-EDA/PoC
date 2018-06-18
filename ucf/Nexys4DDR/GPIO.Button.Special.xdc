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
## Special Buttons
## -----------------------------------------------------------------------------
##  Bank:            15
##    VCCO:          3.3V (VCC3V3)
##  Location:        CPU RESET
## -----------------------------------------------------------------------------
## {IN}    CPU RESET; low-active; external 4k7 pullup resistor
set_property PACKAGE_PIN  C12       [ get_ports Nexys4DDR_GPIO_Button_CPU_Reset_n ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports Nexys4DDR_GPIO_Button_CPU_Reset_n ]
# Ignore timings on async I/O pins
set_false_path                -from [ get_ports Nexys4DDR_GPIO_Button_CPU_Reset_n ]
