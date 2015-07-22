##
## LEDs
## =============================================================================
##	Bank:						15
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				DS2, DS3, DS4, DS5, DS6, DS7, DS8, DS9
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN	AM39			[get_ports VC707_GPIO_LED[0]]						## DS2
set_property PACKAGE_PIN	AN39			[get_ports VC707_GPIO_LED[1]]						## DS3
set_property PACKAGE_PIN	AR37			[get_ports VC707_GPIO_LED[2]]						## DS4
set_property PACKAGE_PIN	AT37			[get_ports VC707_GPIO_LED[3]]						## DS5
set_property PACKAGE_PIN	AR35			[get_ports VC707_GPIO_LED[4]]						## DS6
set_property PACKAGE_PIN	AP41			[get_ports VC707_GPIO_LED[5]]						## DS7
set_property PACKAGE_PIN	AP42			[get_ports VC707_GPIO_LED[6]]						## DS8
set_property PACKAGE_PIN	AU39			[get_ports VC707_GPIO_LED[7]]						## DS9
set_property IOSTANDARD		LVCMOS18	[get_ports -regexp {VC707_GPIO_LED\[\d\]}]

# Ignore timings on async I/O pins
set_false_path -from	[get_ports -regexp {VC707_GPIO_LED\[\d\]}]
