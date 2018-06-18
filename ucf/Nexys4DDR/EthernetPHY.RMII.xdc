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
## single-ended, parallel TX path
## -------------------------------------
## {OUT}    CLKIN
set_property PACKAGE_PIN  D5        [ get_ports Nexys4DDR_EthernetPHY_Clock ]
##
## single-ended, parallel TX path
## -------------------------------------
## {OUT}    TXD0
set_property PACKAGE_PIN  A10       [ get_ports Nexys4DDR_EthernetPHY_TX_Data[0] ]
## {OUT}    TXD1
set_property PACKAGE_PIN  A8        [ get_ports Nexys4DDR_EthernetPHY_TX_Data[1] ]]
## {OUT}    TXEN
set_property PACKAGE_PIN  B9        [ get_ports Nexys4DDR_EthernetPHY_TX_Valid ]
##
##
## single-ended, parallel RX path
## -------------------------------------
## {IN}     RXD0
set_property PACKAGE_PIN  C11       [ get_ports Nexys4DDR_EthernetPHY_RX_Data[0] ]
## {IN}     RXD1
set_property PACKAGE_PIN  D10       [ get_ports Nexys4DDR_EthernetPHY_RX_Data[1] ]
## {IN}     CRS_DV
set_property PACKAGE_PIN  D9        [ get_ports Nexys4DDR_EthernetPHY_RX_Valid ]
## {IN}     RXERR
set_property PACKAGE_PIN  C10       [ get_ports Nexys4DDR_EthernetPHY_RX_Error ]
