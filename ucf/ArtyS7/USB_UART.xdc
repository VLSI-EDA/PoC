##
## USB UART
## -----------------------------------------------------------------------------
##	Bank:						14
##		VCCO:					3.3V (VCC3V3)
##	Location:				IC9
##		Vendor:				FTDI
##		Device:				FT2232
##		Baud-Rate:		300 Bd - 1 MBd
##	Note:						USB-UART is the master, FPGA is the slave => so TX is an input and RX an output
## {IN}			{IN}
set_property PACKAGE_PIN  V12       [ get_ports ArtyS7_USB_UART_TX ]
## {OUT}		{OUT}
set_property PACKAGE_PIN  R12       [ get_ports ArtyS7_USB_UART_RX ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyS7_USB_UART_.*} ]
# Ignore timings on async I/O pins
set_false_path               -from  [ get_ports ArtyS7_USB_UART_TX ]
set_false_path               -to    [ get_ports ArtyS7_USB_UART_RX ]
