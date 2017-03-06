##
## USB UART
## -----------------------------------------------------------------------------
##	Bank:						13
##		VCCO:					1.8V (FPGA_1V8)
##	Location:				U44
##		Vendor:				Silicon Labs
##		Device:				CP2103-GM
##		Baud-Rate:		300 Bd - 1 MBd
##	Note:						USB-UART is the master, FPGA is the slave => so TX is an input and RX an output
## {IN}			U44.25 {OUT}
set_property PACKAGE_PIN	T19				[get_ports AC701_USB_UART_TX]
## {OUT}		U44.24 {IN}
set_property PACKAGE_PIN	U19				[get_ports AC701_USB_UART_RX]
## {IN}			U44.23 {OUT}	Ready to Transmit (USB-UART has new data)
set_property PACKAGE_PIN	V19				[get_ports AC701_USB_UART_RTS_n]
## {OUT}		U44.22 {IN}		Clear to Send (FPGA is able to receive data)
set_property PACKAGE_PIN	W19				[get_ports AC701_USB_UART_CTS_n]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {AC701_USB_UART_.*}]
# Ignore timings on async I/O pins
set_false_path								-from	[get_ports AC701_USB_UART_TX]
set_false_path								-to		[get_ports AC701_USB_UART_RX]
set_false_path								-from	[get_ports AC701_USB_UART_RTS_n]
set_false_path								-to		[get_ports AC701_USB_UART_CTS_n]
