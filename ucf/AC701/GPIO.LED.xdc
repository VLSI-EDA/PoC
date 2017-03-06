## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##	Bank:						14
##		VCCO:					3.3V (FPGA_3V3)
##	Location:				DS2, DS3, DS4, DS5
## -----------------------------------------------------------------------------
## {OUT}	DS2;
set_property PACKAGE_PIN	M26				[get_ports AC701_GPIO_LED[0]]
## {OUT}	DS3;
set_property PACKAGE_PIN	T24				[get_ports AC701_GPIO_LED[1]]
## {OUT}	DS4;
set_property PACKAGE_PIN	T25				[get_ports AC701_GPIO_LED[2]]
## {OUT}	DS5;
set_property PACKAGE_PIN	R26				[get_ports AC701_GPIO_LED[3]]
# set I/O standard
set_property IOSTANDARD		LVCMOS33	[get_ports -regexp {AC701_GPIO_LED\[[0-3]]}]

# Ignore timings on async I/O pins
set_false_path									-to [get_ports -regexp {AC701_GPIO_LED\[\d\]}]
