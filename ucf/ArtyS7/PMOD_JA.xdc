## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyS7
## FPGA:          Xilinx Spartan 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JA
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						14
##	VCCO:						3.3V (VCC3V3)
##	Location:					JA1_P,JA1_N,JA2_P,JA2_N,JA3_P,JA3_N,JA4_P,JA4_N
## -----------------------------------------------------------------------------

## {IN}			JA1_P
set_property PACKAGE_PIN  L17        [ get_ports ArtyS7_PMOD_PortA[0] ]  
## {IN}			JA1_N                                        
set_property PACKAGE_PIN  L18        [ get_ports ArtyS7_PMOD_PortA[1] ]  
## {IN}			JA2_P                                       
set_property PACKAGE_PIN  M14        [ get_ports ArtyS7_PMOD_PortA[2] ]  
## {IN}			JA2_N                                       
set_property PACKAGE_PIN  N14        [ get_ports ArtyS7_PMOD_PortA[3] ]  
## {IN}			JA3_P                                         
set_property PACKAGE_PIN  M16        [ get_ports ArtyS7_PMOD_PortA[4] ]  
## {IN}			JA3_N                                         
set_property PACKAGE_PIN  M17        [ get_ports ArtyS7_PMOD_PortA[5] ]  
## {IN}			JA4_P                                         
set_property PACKAGE_PIN  M18        [ get_ports ArtyS7_PMOD_PortA[6] ]  
## {IN}			JA4_N                                        
set_property PACKAGE_PIN  N18        [ get_ports ArtyS7_PMOD_PortA[7] ]  


