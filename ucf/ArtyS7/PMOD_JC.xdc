## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyS7
## FPGA:          Xilinx Spartan 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JC
## =============================================================================================================================================================
## -------------------------------------------------------------------------------------------------------------
##	Bank:						14,CONFIG
##	VCCO:						3.3V (VCC3V3)
##	Location:					JC[1]/CK_IO[41],JC[2]/CK_IO[40],JC[3]/CK_IO[39],JC[4]/CK_IO[38],JC[7]/CK_IO[37],
								JC[8]/CK_IO[36],JC[9]/CK_IO[35],JC[10]/CK_IO[34]
## -------------------------------------------------------------------------------------------------------------

## {IN}			JC[1]/CK_IO[41]
set_property PACKAGE_PIN  U15        [ get_ports ArtyS7_PMOD_JC_Port[0] ]  
## {IN}			JC[2]/CK_IO[40]                                   
set_property PACKAGE_PIN  V16        [ get_ports ArtyS7_PMOD_JC_Port[1] ]  
## {IN}			JC[3]/CK_IO[39]                                   
set_property PACKAGE_PIN  U17        [ get_ports ArtyS7_PMOD_JC_Port[2] ]  
## {IN}			JC[4]/CK_IO[38]                                   
set_property PACKAGE_PIN  U18        [ get_ports ArtyS7_PMOD_JC_Port[3] ]  
## {IN}			JC[7]/CK_IO[37]                                   
set_property PACKAGE_PIN  U16        [ get_ports ArtyS7_PMOD_JC_Port[4] ]  
## {IN}			JC[8]/CK_IO[36]                                   
set_property PACKAGE_PIN  P13        [ get_ports ArtyS7_PMOD_JC_Port[5] ]  
## {IN}			JC[9]/CK_IO[35]                                   
set_property PACKAGE_PIN  R13        [ get_ports ArtyS7_PMOD_JC_Port[6] ]  
## {IN}			JC[10]/CK_IO[34]                                  
set_property PACKAGE_PIN  V14        [ get_ports ArtyS7_PMOD_JC_Port[7] ] 

