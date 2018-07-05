## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
##	Board:					Digilent - Arty S7
##	FPGA:						Xilinx Spartan-7
##		Device:				XC7S50
##		Package:			CSGA324
##		Speedgrade:		
##
## =============================================================================================================================================================
## Clock Sources
## =============================================================================================================================================================
##
## System Clock
## -----------------------------------------------------------------------------
##		Bank:						15
##			VCCO:					3.3V (VCC3V3)
##		Location:				IC2 (ASEM1)
##			Vendor:				Abracon Corp.
##			Device:				ASEM1-100.000Mhz-LC-T - 1 to 150 MHz Ultra Miniature Pure Silicon Clock Oscillator
##			Frequency:		12 MHz, 50ppm
set_property PACKAGE_PIN    F14       [ get_ports ArtyS7_SystemClock_12MHz ]
# set I/O standard
set_property IOSTANDARD     LVCMOS33  [ get_ports ArtyS7_SystemClock_12MHz ]
# specify a 12 MHz clock
create_clock -period 12.000 -name PIN_SystemClock_12MHz [ get_ports ArtyS7_SystemClock_12MHz ]
