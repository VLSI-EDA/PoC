## =============================================================================================================================================================
## Xilinx User Constraint File (UCF)
## =============================================================================================================================================================
##	Board:					Xilinx - Kintex 7 KC705
##	FPGA:						Xilinx Kintex 7
##		Device:				XC7K325T
##		Package:			FFG900
##		Speedgrade:		-2
##	
##	Notes:
##		Power Rail 4 driving VADJ_FPGA is defaulted to 2.5V (choices: 1.8V, 2.5V, 3.3V)
##
## =============================================================================================================================================================
## Clock Sources
## =============================================================================================================================================================
##
## System Clock
## -----------------------------------------------------------------------------
##		Bank:						33
##			VCCO:					1.5V (VCC1V5_FPGA)
##		Location:				U6 (SIT9102)
##			Vendor:				SiTime
##			Device:				SIT9102AI-243N25E200.0000 - 1 to 220 MHz High Performance Oscillator
##			Frequency:		200 MHz, 50ppm
set_property PACKAGE_PIN	AD12		[get_ports KC705_SystemClock_200MHz_p]
set_property PACKAGE_PIN	AD11		[get_ports KC705_SystemClock_200MHz_n]
# set I/O standard
set_property IOSTANDARD		LVDS		[get_ports -regexp {KC705_SystemClock_200MHz_[p|n]}]
# specify a 200 MHz clock
create_clock -period 5.000 -name NET_SystemClock_200MHz [get_ports KC705_SystemClock_200MHz_p]
