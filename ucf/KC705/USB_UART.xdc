##
## USB UART
## -----------------------------------------------------------------------------
##	Bank:						15
##		VCCO:					2.5V (VCC2V5_FPGA)
##	Location:				U12
##		Vendor:				Silicon Labs
##		Device:				CP2103-GM
##		Baud-Rate:		300 Bd - 1 MBd
##	Note:						USB-UART is the master, FPGA is the slave => so TX is an input and RX an output
## {IN}			U34.25 {OUT}
set_property PACKAGE_PIN	M19				[get_ports KC705_USB_UART_TX]
## {OUT}		U34.24 {IN}
set_property PACKAGE_PIN	K24				[get_ports KC705_USB_UART_RX]
## {IN}			U34.23 {OUT}	Ready to Transmit (USB-UART has new data)
set_property PACKAGE_PIN	K23				[get_ports KC705_USB_UART_RTS]
## {OUT}		U34.22 {IN}		Clear to Send (FPGA is able to receive data)
set_property PACKAGE_PIN	L27				[get_ports KC705_USB_UART_CTS]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {KC705_USB_UART_.*}]
# Ignore timings on async I/O pins
set_false_path								-from	[get_ports KC705_USB_UART_TX]
set_false_path								-to		[get_ports KC705_USB_UART_RX]
set_false_path								-from	[get_ports KC705_USB_UART_RTS]
set_false_path								-to		[get_ports KC705_USB_UART_CTS]
