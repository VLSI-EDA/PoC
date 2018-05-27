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
## Video Interface
## =============================================================================================================================================================
##
## VGA
## -----------------------------------------------------------------------------
##  Bank:            
##    VCCO:          3.3V (VCC3V3)
##  Location:        J2
## -----------------------------------------------------------------------------
## {OUT}   J2
set_property PACKAGE_PIN  A3        [ get_ports Nexys4DDR_Bus_VGA_R[0] ]
set_property PACKAGE_PIN  B4        [ get_ports Nexys4DDR_Bus_VGA_R[1] ]
set_property PACKAGE_PIN  C5        [ get_ports Nexys4DDR_Bus_VGA_R[2] ]
set_property PACKAGE_PIN  A4        [ get_ports Nexys4DDR_Bus_VGA_R[3] ]
## {OUT}   J2
set_property PACKAGE_PIN  C6        [ get_ports Nexys4DDR_Bus_VGA_G[0] ]
set_property PACKAGE_PIN  A5        [ get_ports Nexys4DDR_Bus_VGA_G[1] ]
set_property PACKAGE_PIN  B6        [ get_ports Nexys4DDR_Bus_VGA_G[2] ]
set_property PACKAGE_PIN  A6        [ get_ports Nexys4DDR_Bus_VGA_G[3] ]
## {OUT}   J2
set_property PACKAGE_PIN  B7        [ get_ports Nexys4DDR_Bus_VGA_B[0] ]
set_property PACKAGE_PIN  C7        [ get_ports Nexys4DDR_Bus_VGA_B[1] ]
set_property PACKAGE_PIN  D7        [ get_ports Nexys4DDR_Bus_VGA_B[2] ]
set_property PACKAGE_PIN  D8        [ get_ports Nexys4DDR_Bus_VGA_B[3] ]
## {OUT}   J2
set_property PACKAGE_PIN  B11       [ get_ports Nexys4DDR_Bus_VGA_HSync ]
## {OUT}   J2
set_property PACKAGE_PIN  B12       [ get_ports Nexys4DDR_Bus_VGA_VSync ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4DDR_Bus_VGA_.*} ]
