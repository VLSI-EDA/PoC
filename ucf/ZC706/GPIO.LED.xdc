## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##	Bank:						11, 33, 35
##		VCCO:					2.5, 1.5, 1.5V (VADJ_FPGA, VCC1V5_FPGA, VCC1V5_FPGA)
##	Location:				Q30, Q9, Q8, Q7
## -----------------------------------------------------------------------------
## {OUT}	Q30; Bank 35; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	A17				[get_ports ZC706_GPIO_LED[0]]
## {OUT}	Q9; Bank 11; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	W21				[get_ports ZC706_GPIO_LED[1]]
## {OUT}	Q8; Bank 33; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	G2				[get_ports ZC706_GPIO_LED[2]]
## {OUT}	Q7; Bank 11; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	Y21				[get_ports ZC706_GPIO_LED[3]]
# set I/O standard
set_property IOSTANDARD		LVCMOS15	[get_ports ZC706_GPIO_LED[0]]
set_property IOSTANDARD		LVCMOS25	[get_ports ZC706_GPIO_LED[1]]
set_property IOSTANDARD		LVCMOS15	[get_ports ZC706_GPIO_LED[2]]
set_property IOSTANDARD		LVCMOS25	[get_ports ZC706_GPIO_LED[3]]
# Ignore timings on async I/O pins
set_false_path									-to [get_ports -regexp {ZC706_GPIO_LED\[\d\]}]
