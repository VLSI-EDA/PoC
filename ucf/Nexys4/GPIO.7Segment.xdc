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
## 7 Segment Display (8 Digits, Time Multiplexed)
## -----------------------------------------------------------------------------
##  Bank:            
##    VCCO:          3.3V (VCC3V3)
##  Location:        DISP1, DISP2
## -----------------------------------------------------------------------------
## {OUT}  AN0
set_property PACKAGE_PIN  N6        [ get_ports Nexys4_GPIO_7Segment_Anode[0] ]
## {OUT}  AN1
set_property PACKAGE_PIN  M6        [ get_ports Nexys4_GPIO_7Segment_Anode[1] ]
## {OUT}  AN2
set_property PACKAGE_PIN  M3        [ get_ports Nexys4_GPIO_7Segment_Anode[2] ]
## {OUT}  AN3
set_property PACKAGE_PIN  N5        [ get_ports Nexys4_GPIO_7Segment_Anode[3] ]
## {OUT}  AN4
set_property PACKAGE_PIN  N2        [ get_ports Nexys4_GPIO_7Segment_Anode[4] ]
## {OUT}  AN5
set_property PACKAGE_PIN  N4        [ get_ports Nexys4_GPIO_7Segment_Anode[5] ]
## {OUT}  AN6
set_property PACKAGE_PIN  L1        [ get_ports Nexys4_GPIO_7Segment_Anode[6] ]
## {OUT}  AN7
set_property PACKAGE_PIN  M1        [ get_ports Nexys4_GPIO_7Segment_Anode[7] ]
##
## {OUT}  CA
set_property PACKAGE_PIN  L3        [ get_ports Nexys4DDR_GPIO_7Segment_Cathode[0] ]
## {OUT}  CB
set_property PACKAGE_PIN  N1        [ get_ports Nexys4DDR_GPIO_7Segment_Cathode[1] ]
## {OUT}  CC
set_property PACKAGE_PIN  L5        [ get_ports Nexys4DDR_GPIO_7Segment_Cathode[2] ]
## {OUT}  CD
set_property PACKAGE_PIN  L4        [ get_ports Nexys4DDR_GPIO_7Segment_Cathode[3] ]
## {OUT}  CE
set_property PACKAGE_PIN  K3        [ get_ports Nexys4DDR_GPIO_7Segment_Cathode[4] ]
## {OUT}  CF
set_property PACKAGE_PIN  M2        [ get_ports Nexys4DDR_GPIO_7Segment_Cathode[5] ]
## {OUT}  CG
set_property PACKAGE_PIN  L6        [ get_ports Nexys4DDR_GPIO_7Segment_Cathode[6] ]
## {OUT}  DP
set_property PACKAGE_PIN  M4        [ get_ports Nexys4DDR_GPIO_7Segment_Cathode[6] ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4_GPIO_7Segment_.*} ]
# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Nexys4_GPIO_7Segment_.*} ]
