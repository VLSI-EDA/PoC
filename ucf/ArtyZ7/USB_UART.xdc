## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyZ7
## FPGA:          Xilinx Zynq 7000
## =============================================================================================================================================================
## USB UART
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:				500		
##	VCCO:				VCC3V3		
##	Location:				
##	Device:				
##	Baud-Rate:			
##	Note:				USB-UART is the master, FPGA is the slave => so TX is an input and RX an output
## -----------------------------------------------------------------------------

## {IN}			{IN}
set_property PACKAGE_PIN  C5       [ get_ports ArtyZ7_USB_UART_TX ]
## {OUT}		{OUT}
set_property PACKAGE_PIN  C8       [ get_ports ArtyZ7_USB_UART_RX ]

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyZ7_USB_UART_.*} ]

# Ignore timings on async I/O pins
set_false_path               -from  [ get_ports ArtyZ7_USB_UART_TX ]
set_false_path               -to    [ get_ports ArtyZ7_USB_UART_RX ]
