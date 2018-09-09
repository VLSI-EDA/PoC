## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## Ethernet PHY
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						15
##	VCCO:						3.3V (VCC3V3)
##	Location:					J9 
## -----------------------------------------------------------------------------

## common signals and management
## -------------------------------------
## {OUT}    
set_property PACKAGE_PIN  C16       [ get_ports EthernetPHY_Reset_n ]			
## {OUT}    
set_property PACKAGE_PIN  G18       [ get_ports EthernetPHY_Reference_Clock ]		
## {OUT}    
set_property PACKAGE_PIN  F16       [ get_ports EthernetPHY_Management_Clock ]	
## {OUT}    
set_property PACKAGE_PIN  G14       [ get_ports EthernetPHY_CRS ]				
## {OUT}    
set_property PACKAGE_PIN  D17       [ get_ports EthernetPHY_COL ]				
## {INOUT}  
set_property PACKAGE_PIN  K13       [ get_ports EthernetPHY_Management_Data ]	

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {EthernetPHY_.*} ]
## Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {EthernetPHY_.*} ]
set_false_path                -from [ get_ports EthernetPHY_Management_Data ]