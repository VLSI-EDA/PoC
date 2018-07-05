## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyZ7
## FPGA:          Xilinx Zynq 7000
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## Ethernet PHY
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						501
##	VCCO:						1.8V (VCC1V8)
##	Location:					J8 
## -----------------------------------------------------------------------------

## single-ended, parallel TX path
## -------------------------------------
## {OUT}    CLKIN
set_property PACKAGE_PIN  A19        [ get_ports ArtyZ7_EthernetPHY_TX_Clock ]	
set_property PACKAGE_PIN  B17        [ get_ports ArtyZ7_EthernetPHY_RX_Clock ]	

##
## single-ended, parallel TX path
## -------------------------------------
## {OUT}    TXD0
set_property PACKAGE_PIN  E14       [ get_ports ArtyZ7_EthernetPHY_TX_Data[0] ]	
## {OUT}    TXD1
set_property PACKAGE_PIN  B18       [ get_ports ArtyZ7_EthernetPHY_TX_Data[1] ]	
## {OUT}    TXD2
set_property PACKAGE_PIN  D10       [ get_ports ArtyZ7_EthernetPHY_TX_Data[2] ]	
## {OUT}    TXD3
set_property PACKAGE_PIN  A17       [ get_ports ArtyZ7_EthernetPHY_TX_Data[3] ]	

## single-ended, parallel RX path
## -------------------------------------
## {IN}     RXD0
set_property PACKAGE_PIN  D11       [ get_ports ArtyZ7_EthernetPHY_RX_Data[0] ]	
## {IN}     RXD1
set_property PACKAGE_PIN  A16       [ get_ports ArtyZ7_EthernetPHY_RX_Data[1] ]	
## {IN}     RXD2
set_property PACKAGE_PIN  F15       [ get_ports ArtyZ7_EthernetPHY_RX_Data[2] ]	
## {IN}     RXD3
set_property PACKAGE_PIN  A15       [ get_ports ArtyZ7_EthernetPHY_RX_Data[3] ]	
