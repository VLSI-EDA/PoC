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
##		VCCO:					3.3V (VCC3V3)
##	Location:					J9 
## -----------------------------------------------------------------------------

## common signals and management
## -------------------------------------
## {OUT}    
set_property PACKAGE_PIN  C16       [ get_ports EthernetPHY_Reset_n ]			#IO_L20P_T3_A20_15	
## {OUT}    
set_property PACKAGE_PIN  G18       [ get_ports EthernetPHY_Reference_Clock ]	#IO_L22P_T3_A17_15			
## {OUT}    
set_property PACKAGE_PIN  F16       [ get_ports EthernetPHY_Management_Clock ]	#IO_L14N_T2_SRCC_15	
## {OUT}    
set_property PACKAGE_PIN  G14       [ get_ports EthernetPHY_CRS ]				#IO_L15N_T2_DQS_ADV_B_15
## {OUT}    
set_property PACKAGE_PIN  D17       [ get_ports EthernetPHY_COL ]				#IO_L16N_T2_A27_15
## {INOUT}  
set_property PACKAGE_PIN  K13       [ get_ports EthernetPHY_Management_Data ]	#IO_L17P_T2_A26_15

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {EthernetPHY_.*} ]
## Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {EthernetPHY_.*} ]
set_false_path                -from [ get_ports EthernetPHY_Management_Data ]