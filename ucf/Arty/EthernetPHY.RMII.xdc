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

## single-ended, parallel TX path
## -------------------------------------
## {OUT}    CLKIN
set_property PACKAGE_PIN  H16        [ get_ports Arty_EthernetPHY_TX_Clock ]	
set_property PACKAGE_PIN  F15        [ get_ports Arty_EthernetPHY_RX_Clock ]	
##
## single-ended, parallel TX path
## -------------------------------------
## {OUT}    TXD0
set_property PACKAGE_PIN  H14       [ get_ports Arty_EthernetPHY_TX_Data[0] ]	
## {OUT}    TXD1
set_property PACKAGE_PIN  J14       [ get_ports Arty_EthernetPHY_TX_Data[1] ]	
## {OUT}    TXD2
set_property PACKAGE_PIN  J13       [ get_ports Arty_EthernetPHY_TX_Data[2] ]	
## {OUT}    TXD3
set_property PACKAGE_PIN  H17       [ get_ports Arty_EthernetPHY_TX_Data[3] ]	
## {OUT}    TXEN
set_property PACKAGE_PIN  H15       [ get_ports Arty_EthernetPHY_TX_Valid ]	
##
##
## single-ended, parallel RX path
## -------------------------------------
## {IN}     RXD0
set_property PACKAGE_PIN  D18       [ get_ports Arty_EthernetPHY_RX_Data[0] ]	
## {IN}     RXD1
set_property PACKAGE_PIN  E17       [ get_ports Arty_EthernetPHY_RX_Data[1] ]	
## {IN}     RXD2
set_property PACKAGE_PIN  E18       [ get_ports Arty_EthernetPHY_RX_Data[2] ]	
## {IN}     RXD3
set_property PACKAGE_PIN  G17       [ get_ports Arty_EthernetPHY_RX_Data[3] ]	
## {IN}     RX_DV
set_property PACKAGE_PIN  G16       [ get_ports Arty_EthernetPHY_RX_Valid ]	
## {IN}     RXERR
set_property PACKAGE_PIN  C17       [ get_ports Arty_EthernetPHY_RX_Error ]	
