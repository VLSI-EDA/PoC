## =============================================================================================================================================================
## Clocks
## =============================================================================================================================================================
##
## System Clock
## =============================================================================
##		Bank:						38
##			VCCO:					1.5V (VCC1V5_FPGA)
##		Location:				U51 (SIT9102)
##			Vendor:				SiTime
##			Device:				SiT9102 - 1 to 220 MHz High Performance Oscillator
##			Frequency:		200 MHz, 50ppm
set_property PACKAGE_PIN	E19		[get_ports VC707_SystemClock_200MHz_p]
set_property PACKAGE_PIN	E18		[get_ports VC707_SystemClock_200MHz_n]
# set I/O standard
set_property IOSTANDARD		LVDS	[get_ports -regexp {VC707_SystemClock_200MHz_[p|n]}]
# specify a 200 MHz clock
create_clock -period 5.000 -name PIN_SystemClock_200MHz [get_ports VC707_SystemClock_200MHz_p]
