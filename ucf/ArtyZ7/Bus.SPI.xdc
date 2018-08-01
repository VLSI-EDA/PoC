## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         	Digilent - ArtyZ7
## FPGA:          	Xilinx Zynq 7000
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## SPI-Bus
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:				34,35				
##	VCCO:				VCC3V3		
##	Location:			J6		
## -----------------------------------------------------------------------------

## {OUT}	SerialClock
set_property PACKAGE_PIN  H15       [ get_ports ArtyZ7_SPI_SerialClock ]
## {OUT}	SlaveSelect
set_property PACKAGE_PIN  F16       [ get_ports ArtyZ7_SPI_SlaveSelect ]
## {OUT}	MOSI (Master Out - Slave In)
set_property PACKAGE_PIN  T12       [ get_ports ArtyZ7_SPI_MOSI ]
## {IN}	  MISO (Master In - Slave Out)
set_property PACKAGE_PIN  W15       [ get_ports ArtyZ7_SPI_MISO ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyZ7_SPI_.*} ]

# Ignore timings on async I/O pins
set_false_path								-to		[ get_ports ArtyZ7_SPI_SerialClock ]
set_false_path								-to		[ get_ports ArtyZ7_SPI_SlaveSelect ]
set_false_path								-to		[ get_ports ArtyZ7_SPI_MOSI        ]
set_false_path								-from	[ get_ports ArtyZ7_SPI_MISO        ]
