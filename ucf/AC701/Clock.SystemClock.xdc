## =============================================================================================================================================================
## Xilinx User Constraint File (UCF)
## =============================================================================================================================================================
##	Board:					Xilinx - Artix-7 AC701
##	FPGA:						Xilinx Artix-7
##		Device:				XC7A200T
##		Package:			FBG676
##		Speedgrade:		-2
##
##	Notes:
##		AC701: VCCO_VADJ is defaulted to 2.5V (choices: 1.8V, 2.5V, 3.3V)
##
## =============================================================================================================================================================
## Clock Sources
## =============================================================================================================================================================
##
## System Clock
## -----------------------------------------------------------------------------
##		Bank:						34
##			VCCO:					2.5V (FPGA_2V5)
##		Location:				U51 (SIT9102)
##			Vendor:				SiTime
##			Device:				SIT9102AI-243N25E200.0000 - 1 to 220 MHz High Performance Oscillator
##			Frequency:		200 MHz, 50ppm
set_property PACKAGE_PIN	R3			[get_ports AC701_SystemClock_200MHz_p]
set_property PACKAGE_PIN	P3			[get_ports AC701_SystemClock_200MHz_n]
# set I/O standard
set_property IOSTANDARD		LVDS_25	[get_ports -regexp {AC701_SystemClock_200MHz_[p|n]}]
# specify a 200 MHz clock
create_clock -period 5.000 -name PIN_SystemClock_200MHz [get_ports AC701_SystemClock_200MHz_p]
