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

## single-ended, parallel TX path
## -------------------------------------
## {OUT}    CLKIN
set_property PACKAGE_PIN  H16        [ get_ports Arty_EthernetPHY_TX_Clock ]	#IO_L13P_T2_MRCC_15
set_property PACKAGE_PIN  F15        [ get_ports Arty_EthernetPHY_RX_Clock ]	#IO_L14P_T2_SRCC_15
##
## single-ended, parallel TX path
## -------------------------------------
## {OUT}    TXD0
set_property PACKAGE_PIN  H14       [ get_ports Arty_EthernetPHY_TX_Data[0] ]	#IO_L15P_T2_DQS_15
## {OUT}    TXD1
set_property PACKAGE_PIN  J14       [ get_ports Arty_EthernetPHY_TX_Data[1] ]	#IO_L19P_T3_A22_15
## {OUT}    TXD2
set_property PACKAGE_PIN  J13       [ get_ports Arty_EthernetPHY_TX_Data[2] ]	#IO_L17N_T2_A25_15
## {OUT}    TXD3
set_property PACKAGE_PIN  H17       [ get_ports Arty_EthernetPHY_TX_Data[3] ]	#IO_L18P_T2_A24_15
## {OUT}    TXEN
set_property PACKAGE_PIN  H15       [ get_ports Arty_EthernetPHY_TX_Valid ]	#IO_L19N_T3_A21_VREF_15
##
##
## single-ended, parallel RX path
## -------------------------------------
## {IN}     RXD0
set_property PACKAGE_PIN  D18       [ get_ports Arty_EthernetPHY_RX_Data[0] ]	#IO_L21N_T3_DQS_A18_15
## {IN}     RXD1
set_property PACKAGE_PIN  E17       [ get_ports Arty_EthernetPHY_RX_Data[1] ]	#IO_L16P_T2_A28_15
## {IN}     RXD2
set_property PACKAGE_PIN  E18       [ get_ports Arty_EthernetPHY_RX_Data[2] ]	#IO_L21P_T3_DQS_15
## {IN}     RXD3
set_property PACKAGE_PIN  G17       [ get_ports Arty_EthernetPHY_RX_Data[3] ]	#IO_L18N_T2_A23_15
## {IN}     RX_DV
set_property PACKAGE_PIN  G16       [ get_ports Arty_EthernetPHY_RX_Valid ]	#IO_L13N_T2_MRCC_15
## {IN}     RXERR
set_property PACKAGE_PIN  C17       [ get_ports Arty_EthernetPHY_RX_Error ]	#IO_L20N_T3_A19_15
