## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JC
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						14
##	VCCO:						3.3V (VCC3V3)
##	Location:					JC1_P,JC1_N,JC2_P,JC2_N,JC3_P,JC3_N,JC4_P,JC4_N
## -----------------------------------------------------------------------------

## {IN}			JC1_P
set_property PACKAGE_PIN  U12        [ get_ports Arty_PMOD_PortC[1]_P ] 
## {IN}			JC1_N                                        
set_property PACKAGE_PIN  V12        [ get_ports Arty_PMOD_PortC[1]_N ] 
## {IN}			JC2_P                                        
set_property PACKAGE_PIN  V10        [ get_ports Arty_PMOD_PortC[2]_P ] 
## {IN}			JC2_N                                        
set_property PACKAGE_PIN  V11        [ get_ports Arty_PMOD_PortC[2]_N ] 
## {IN}			JC3_P                                        
set_property PACKAGE_PIN  U14        [ get_ports Arty_PMOD_PortC[3]_P ] 
## {IN}			JC3_N                                        
set_property PACKAGE_PIN  V14        [ get_ports Arty_PMOD_PortC[3]_N ] 
## {IN}			JC4_P                                        
set_property PACKAGE_PIN  T13        [ get_ports Arty_PMOD_PortC[4]_P ] 
## {IN}			JC4_N                                        
set_property PACKAGE_PIN  U13        [ get_ports Arty_PMOD_PortC[4]_N ] 
