## USB UART
## =============================================================================
##	Bank:						13
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				U44
##		Vendor:
##		Device:
## {IN}
set_property PACKAGE_PIN	AU33			[get_ports VC707_USB_UART_TX]
## {OUT}
set_property PACKAGE_PIN	AU36			[get_ports VC707_USB_UART_RX]
## {IN}
set_property PACKAGE_PIN	AT32			[get_ports VC707_USB_UART_RTS_n]
## {OUT}
set_property PACKAGE_PIN	AR34			[get_ports VC707_USB_UART_CTS_n]
# set I/O standard
set_property IOSTANDARD		LVCMOS18	[get_ports -regexp {VC707_USB_UART_.*}]
# Ignore timings on async I/O pins
set_false_path								-from	[get_ports VC707_USB_UART_TX]
set_false_path								-to		[get_ports VC707_USB_UART_RX]
set_false_path								-from	[get_ports VC707_USB_UART_RTS_n]
set_false_path								-to		[get_ports VC707_USB_UART_CTS_n]
