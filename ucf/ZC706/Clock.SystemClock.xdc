## System Clock
## -----------------------------------------------------------------------------
##		Bank:						34
##			VCCO:					2.5V (VCC2V5_FPGA)
##		Location:				U64 (SIT9102)
##			Vendor:				SiTime
##			Device:				SIT9102AI-243N25E200.0000 - 1 to 220 MHz High Performance Oscillator
##			Frequency:		200 MHz, 50ppm
set_property PACKAGE_PIN	H9		[get_ports ZC706_SystemClock_200MHz_p]
set_property PACKAGE_PIN	G9		[get_ports ZC706_SystemClock_200MHz_n]
# set I/O standard
set_property IOSTANDARD		LVDS		[get_ports -regexp {ZC706_SystemClock_200MHz_[p|n]}]
# specify a 200 MHz clock
create_clock -period 5.000 -name PIN_SystemClock_200MHz [get_ports ZC706_SystemClock_200MHz_p]
