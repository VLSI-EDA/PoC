##
## SPI-Bus
## -----------------------------------------------------------------------------
##	Bank:						15
##		VCCO:					3.3V (VCC3V3)
##	Location:				J7 (2x3 header)
## -----------------------------------------------------------------------------
## {OUT}	SerialClock
set_property PACKAGE_PIN  G16       [ get_ports ArtyS7_SPI_SerialClock ]
## {OUT}	SlaveSelect
set_property PACKAGE_PIN  H16       [ get_ports ArtyS7_SPI_SlaveSelect ]
## {OUT}	MOSI (Master Out - Slave In)
set_property PACKAGE_PIN  H17       [ get_ports ArtyS7_SPI_MOSI ]
## {IN}	  MISO (Master In - Slave Out)
set_property PACKAGE_PIN  K14       [ get_ports ArtyS7_SPI_MISO ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyS7_SPI_.*} ]

# Ignore timings on async I/O pins
set_false_path								-to		[ get_ports ArtyS7_SPI_SerialClock ]
set_false_path								-to		[ get_ports ArtyS7_SPI_SlaveSelect ]
set_false_path								-to		[ get_ports ArtyS7_SPI_MOSI        ]
set_false_path								-from	[ get_ports ArtyS7_SPI_MISO        ]
