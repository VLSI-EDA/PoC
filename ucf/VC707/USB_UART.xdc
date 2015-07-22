## USB UART
## =============================================================================
##	Bank:						13
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				U44
##		Vendor:				
##		Device:				
set_property PACKAGE_PIN	AU36			[get_ports VC707_USB_UART_RX]							## 
set_property PACKAGE_PIN	AT32			[get_ports VC707_USB_UART_RTS]						## 
set_property PACKAGE_PIN	AU33			[get_ports VC707_USB_UART_TX]							## 
set_property PACKAGE_PIN	AR34			[get_ports VC707_USB_UART_CTS]						## 
set_property IOSTANDARD		LVCMOS18	[get_ports -regexp {VC707_USB_UART_.*}]

# Ignore timings on async I/O pins
set_false_path -from	[get_ports VC707_USB_UART_TX]
set_false_path -from	[get_ports VC707_USB_UART_CTS]
set_false_path -to		[get_ports VC707_USB_UART_RX]
set_false_path -to		[get_ports VC707_USB_UART_RTS]
