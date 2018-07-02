## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyS7
## FPGA:          Xilinx Spartan 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JD
## =============================================================================================================================================================
## -------------------------------------------------------------------------------------------------------------
##	Bank:						14
##	VCCO:						3.3V (VCC3V3)
##	Location:					JD[1]/CK_IO[33],JD[2]/CK_IO[32],JD[3]/CK_IO[31],JD[4]/CK_IO[30],JD[7]/CK_IO[29],
								JD[8]/CK_IO[28],JD[9]/CK_IO[27],JD[10]/CK_IO[26]
## -------------------------------------------------------------------------------------------------------------

## {IN}			JD[1]/CK_IO[33]
set_property PACKAGE_PIN  V15        [ get_ports ArtyS7_PMOD_PortJD[0] ]  
## {IN}			JD[2]/CK_IO[32]                                   
set_property PACKAGE_PIN  U12        [ get_ports ArtyS7_PMOD_PortJD[1] ]  
## {IN}			JD[3]/CK_IO[31]                                   
set_property PACKAGE_PIN  V13        [ get_ports ArtyS7_PMOD_PortJD[2] ]  
## {IN}			JD[4]/CK_IO[30]                                   
set_property PACKAGE_PIN  T12        [ get_ports ArtyS7_PMOD_PortJD[3] ]  
## {IN}			JD[7]/CK_IO[29]                                   
set_property PACKAGE_PIN  T13        [ get_ports ArtyS7_PMOD_PortJD[4] ]  
## {IN}			JD[8]/CK_IO[28]                                   
set_property PACKAGE_PIN  R11        [ get_ports ArtyS7_PMOD_PortJD[5] ]  
## {IN}			JD[9]/CK_IO[27]                                   
set_property PACKAGE_PIN  T11        [ get_ports ArtyS7_PMOD_PortJD[6] ]  
## {IN}			JD[10]/CK_IO[26]                                  
set_property PACKAGE_PIN  U11        [ get_ports ArtyS7_PMOD_PortJD[7] ] 

