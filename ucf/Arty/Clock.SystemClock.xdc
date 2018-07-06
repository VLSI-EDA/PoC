## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
##	Board:					Digilent - Arty
##	FPGA:						Xilinx Artix-7
##		Device:				XC7A35T
##		Package:			CSG324
##		Speedgrade:		-1
##
## =============================================================================================================================================================
## Clock Sources
## =============================================================================================================================================================
##
## System Clock
## -----------------------------------------------------------------------------
##		Bank:						35
##			VCCO:					3.3V (VCC3V3)
##		Location:				IC2 (ASEM1)
##			Vendor:				Abracon Corp.
##			Device:				ASEM1-100.000Mhz-LC-T - 1 to 150 MHz Ultra Miniature Pure Silicon Clock Oscillator
##			Frequency:		100 MHz, 50ppm
set_property PACKAGE_PIN    E3        [ get_ports Arty_SystemClock_100MHz ]
# set I/O standard
set_property IOSTANDARD     LVCMOS33  [ get_ports Arty_SystemClock_100MHz ]
# specify a 100 MHz clock
create_clock -period 10*10-9ns -name PIN_SystemClock_100MHz [ get_ports Arty_SystemClock_100MHz ]
