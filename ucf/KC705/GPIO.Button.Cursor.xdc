## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## Cursor Buttons
## -----------------------------------------------------------------------------
##	Bank:						18, 33, 34
##		VCCO:					2.5V, 1.5V, 1.5V (VADJ_FPGA, VCC1V5_FPGA, VCC1V5_FPGA)
##	Location:				SW2, SW3, SW4, SW5, SW6
## -----------------------------------------------------------------------------
## {IN}		SW2; high-active; external 4k7 pulldown resistor; Bank 33; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	AA12			[get_ports KC705_GPIO_Button_North]
## {IN}		SW6; high-active; external 4k7 pulldown resistor; Bank 34; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	AC6				[get_ports KC705_GPIO_Button_West]
## {IN}		SW5; high-active; external 4k7 pulldown resistor; Bank 18; VCCO=VADJ_FPGA
set_property PACKAGE_PIN	G12				[get_ports KC705_GPIO_Button_Center]
## {IN}		SW3; high-active; external 4k7 pulldown resistor; Bank 34; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	AG5				[get_ports KC705_GPIO_Button_East]
## {IN}		SW4; high-active; external 4k7 pulldown resistor; Bank 33; VCCO=VCC1V5_FPGA
set_property PACKAGE_PIN	AB12			[get_ports KC705_GPIO_Button_South]
# set I/O standard
set_property IOSTANDARD		LVCMOS15	[get_ports -regexp {KC705_GPIO_Button_.*}]
# Ignore timings on async I/O pins
set_false_path								-from [get_ports -regexp {KC705_GPIO_Button_.*}]
