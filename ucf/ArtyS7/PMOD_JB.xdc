## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyS7
## FPGA:          Xilinx Spartan 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JB
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						14
##	VCCO:						3.3V (VCC3V3)
##	Location:					JB1_P,JB1_N,JB2_P,JB2_N,JB3_P,JB3_N,JB4_P,JB4_N
## -----------------------------------------------------------------------------

## {IN}			JB1_P
set_property PACKAGE_PIN  P17        [ get_ports ArtyS7_PMOD_PortJB[0] ] 
## {IN}			JB1_N                                
set_property PACKAGE_PIN  P18        [ get_ports ArtyS7_PMOD_PortJB[1] ] 
## {IN}			JB2_P                               
set_property PACKAGE_PIN  R18        [ get_ports ArtyS7_PMOD_PortJB[2] ] 
## {IN}			JB2_N                                
set_property PACKAGE_PIN  T18        [ get_ports ArtyS7_PMOD_PortJB[3] ] 
## {IN}			JB3_P                                
set_property PACKAGE_PIN  P14        [ get_ports ArtyS7_PMOD_PortJB[4] ] 
## {IN}			JB3_N                                
set_property PACKAGE_PIN  P15        [ get_ports ArtyS7_PMOD_PortJB[5] ] 
## {IN}			JB4_P                                
set_property PACKAGE_PIN  N15        [ get_ports ArtyS7_PMOD_PortJB[6] ] 
## {IN}			JB4_N                                
set_property PACKAGE_PIN  P16        [ get_ports ArtyS7_PMOD_PortJB[7] ] 

