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
## Low-Speed Bus
## =============================================================================================================================================================
##
## USB UART
## -----------------------------------------------------------------------------
##  Bank:            
##    VCCO:          3.3V (VCC3V3)
##  Location:        IC7 FT2232
##    Vendor:        FTDI
##    Device:        FT2232HQ
##    Baud-Rate:    
##  Note:            USB-UART is the master, FPGA is the slave => so TX is an input and RX an output
## {IN}      IC7.?? {OUT}
set_property PACKAGE_PIN  C4        [ get_ports Nexys4DDR_USB_UART_TX ]
## {OUT}    IC7.?? {IN}
set_property PACKAGE_PIN  D4        [ get_ports Nexys4DDR_USB_UART_RX ]
## {IN}      IC7.?? {OUT}  Ready to Transmit (USB-UART has new data)
set_property PACKAGE_PIN  E5        [ get_ports Nexys4DDR_USB_UART_RTS_n ]
## {OUT}    IC7.?? {IN}    Clear to Send (FPGA is able to receive data)
set_property PACKAGE_PIN  D3        [ get_ports Nexys4DDR_USB_UART_CTS_n ]
# set I/O standard
set_property IOSTANDARD   LVCMOS25  [ get_ports -regexp {Nexys4DDR_USB_UART_.*} ]
# Ignore timings on async I/O pins
set_false_path               -from  [ get_ports Nexys4DDR_USB_UART_TX ]
set_false_path               -to    [ get_ports Nexys4DDR_USB_UART_RX ]
set_false_path               -from  [ get_ports Nexys4DDR_USB_UART_RTS_n ]
set_false_path               -to    [ get_ports Nexys4DDR_USB_UART_CTS_n ]
