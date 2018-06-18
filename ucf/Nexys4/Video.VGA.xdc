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
set_property PACKAGE_PIN  R5        [ get_ports Nexys4_Bus_VGA_R[0] ]
set_property PACKAGE_PIN  R3        [ get_ports Nexys4_Bus_VGA_R[1] ]
set_property PACKAGE_PIN  R2        [ get_ports Nexys4_Bus_VGA_R[2] ]
set_property PACKAGE_PIN  R1        [ get_ports Nexys4_Bus_VGA_R[3] ]
## {OUT}   J2
set_property PACKAGE_PIN  P2        [ get_ports Nexys4_Bus_VGA_G[0] ]
set_property PACKAGE_PIN  N2        [ get_ports Nexys4_Bus_VGA_G[1] ]
set_property PACKAGE_PIN  N1        [ get_ports Nexys4_Bus_VGA_G[2] ]
set_property PACKAGE_PIN  M3        [ get_ports Nexys4_Bus_VGA_G[3] ]
## {OUT}   J2
set_property PACKAGE_PIN  M1        [ get_ports Nexys4_Bus_VGA_B[0] ]
set_property PACKAGE_PIN  M2        [ get_ports Nexys4_Bus_VGA_B[1] ]
set_property PACKAGE_PIN  L1        [ get_ports Nexys4_Bus_VGA_B[2] ]
set_property PACKAGE_PIN  L3        [ get_ports Nexys4_Bus_VGA_B[3] ]
## {OUT}   J2
set_property PACKAGE_PIN  L14       [ get_ports Nexys4_Bus_VGA_HSync ]
## {OUT}   J2
set_property PACKAGE_PIN  K3        [ get_ports Nexys4_Bus_VGA_VSync ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4_Bus_VGA_.*} ]
