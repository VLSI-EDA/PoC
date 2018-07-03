## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JB
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						15
##	VCCO:						3.3V (VCC3V3)
##	Location:					JB1_P,JB1_N,JB2_P,JB2_N,JB3_P,JB3_N,JB4_P,JB4_N
## -----------------------------------------------------------------------------

## {IN}			JB1_P
set_property PACKAGE_PIN  E15        [ get_ports Arty_PMOD_PortB[1]_P ] 
## {IN}			JB1_N
set_property PACKAGE_PIN  E16        [ get_ports Arty_PMOD_PortB[1]_N ] 
## {IN}			JB2_P
set_property PACKAGE_PIN  D15        [ get_ports Arty_PMOD_PortB[2]_P ] 
## {IN}			JB2_N
set_property PACKAGE_PIN  C15        [ get_ports Arty_PMOD_PortB[2]_N ] 
## {IN}			JB3_P
set_property PACKAGE_PIN  J17        [ get_ports Arty_PMOD_PortB[3]_P ] 
## {IN}			JB3_N
set_property PACKAGE_PIN  J18        [ get_ports Arty_PMOD_PortB[3]_N ] 
## {IN}			JB4_P
set_property PACKAGE_PIN  K15        [ get_ports Arty_PMOD_PortB[4]_P ] 
## {IN}			JB4_N
set_property PACKAGE_PIN  J15        [ get_ports Arty_PMOD_PortB[4]_N ] 
