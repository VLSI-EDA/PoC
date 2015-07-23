## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##	Bank:						17, 18, 33
##		VCCO:					2.5, 2.5, 1.5V (VADJ_FPGA, VADJ_FPGA, VCC1V5_FPGA)
##	Location:				DS1, DS2, DS3, DS4, DS10, DS25, DS26, DS27
## -----------------------------------------------------------------------------
## {OUT}	DS4; Bank 33; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	AB8				[get_ports KC705_GPIO_LED[0]]
## {OUT}	DS1; Bank 33; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	AA8				[get_ports KC705_GPIO_LED[1]]
## {OUT}	DS10; Bank 33; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	AC9				[get_ports KC705_GPIO_LED[2]]
## {OUT}	DS2; Bank 33; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	AB9				[get_ports KC705_GPIO_LED[3]]
## {OUT}	DS3; Bank 13; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	AE26			[get_ports KC705_GPIO_LED[4]]
## {OUT}	DS25; Bank 17; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	G19				[get_ports KC705_GPIO_LED[5]]
## {OUT}	DS26; Bank 17; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	E18				[get_ports KC705_GPIO_LED[6]]
## {OUT}	DS27; Bank 18; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	F16				[get_ports KC705_GPIO_LED[7]]
# set I/O standard
set_property IOSTANDARD		LVCMOS15	[get_ports -regexp {KC705_GPIO_LED\[[0-3]]}]
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {KC705_GPIO_LED\[[4-7]]}]
# Ignore timings on async I/O pins
#set_false_path									-to [get_ports -regexp {KC705_GPIO_LED\[\d\]}]
