## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyZ7
## FPGA:          Xilinx Zynq 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JB
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						34
##	VCCO:						3.3V (VCC3V3)
##	Location:					JB1_P,JB1_N,JB2_P,JB2_N,JB3_P,JB3_N,JB4_P,JB4_N
## -----------------------------------------------------------------------------

## {IN}			JB1_P
set_property PACKAGE_PIN  W14        [ get_ports ArtyZ7_PMOD_JB_Port[0] ] 
## {IN}			JB1_N                                
set_property PACKAGE_PIN  Y14        [ get_ports ArtyZ7_PMOD_JB_Port[1] ] 
## {IN}			JB2_P                               
set_property PACKAGE_PIN  T11        [ get_ports ArtyZ7_PMOD_JB_Port[2] ] 
## {IN}			JB2_N                                
set_property PACKAGE_PIN  T10        [ get_ports ArtyZ7_PMOD_JB_Port[3] ] 
## {IN}			JB3_P                                
set_property PACKAGE_PIN  V16        [ get_ports ArtyZ7_PMOD_JB_Port[4] ] 
## {IN}			JB3_N                                
set_property PACKAGE_PIN  W16        [ get_ports ArtyZ7_PMOD_JB_Port[5] ] 
## {IN}			JB4_P                                
set_property PACKAGE_PIN  V12        [ get_ports ArtyZ7_PMOD_JB_Port[6] ] 
## {IN}			JB4_N                                
set_property PACKAGE_PIN  W13        [ get_ports ArtyZ7_PMOD_JB_Port[7] ] 

