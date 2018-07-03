## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JA
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						15
##	VCCO:						3.3V (VCC3V3)
##	Location:					JA1,JA2,JA3,JA4,JA7,JA8,JA9,JA10
## -----------------------------------------------------------------------------

## {IN}			JA1
set_property PACKAGE_PIN  G13        [ get_ports Arty_PMOD_PortA[1] ]  
## {IN}			JA2
set_property PACKAGE_PIN  B11        [ get_ports Arty_PMOD_PortA[2] ]  
## {IN}			JA3
set_property PACKAGE_PIN  A11        [ get_ports Arty_PMOD_PortA[3] ]  
## {IN}			JA4
set_property PACKAGE_PIN  D12        [ get_ports Arty_PMOD_PortA[4] ]  
## {IN}			JA7
set_property PACKAGE_PIN  D13        [ get_ports Arty_PMOD_PortA[7] ]  
## {IN}			JA8
set_property PACKAGE_PIN  B18        [ get_ports Arty_PMOD_PortA[8] ]  
## {IN}			JA9
set_property PACKAGE_PIN  A18        [ get_ports Arty_PMOD_PortA[9] ]  
## {IN}			JA10
set_property PACKAGE_PIN  K16        [ get_ports Arty_PMOD_PortA[10] ] 
