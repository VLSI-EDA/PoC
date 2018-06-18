## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Nexys 4 DDR
## FPGA:          Xilinx Artix 7
##   Device:      XC7A100T
##   Package:     CSG324
##   Speedgrade:  -1
##
## =============================================================================================================================================================
## Ethernet Interface
## =============================================================================================================================================================
##
## Ethernet PHY - SMSC LAN8720A
## -----------------------------------------------------------------------------
##	Bank:						
##		VCCO:					3.3V (VCC3V3)
##	Location:				IC4
##		Vendor:				SMSC / Microchip
##		Device:				LAN8720A
##		MDIO-Address:	0x01 (---0 0001b)
##
## common signals and management
## -------------------------------------
## {OUT}    
set_property PACKAGE_PIN  B3        [ get_ports EthernetPHY_Reset_n ]
## {OUT}    
set_property PACKAGE_PIN  C9        [ get_ports EthernetPHY_Management_Clock ]
## {INOUT}  
set_property PACKAGE_PIN  A9        [ get_ports EthernetPHY_Management_Data ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {EthernetPHY_.*} ]
## Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {EthernetPHY_.*} ]
set_false_path                -from [ get_ports EthernetPHY_Management_Data ]
