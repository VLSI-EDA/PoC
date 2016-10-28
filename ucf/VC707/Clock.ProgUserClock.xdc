##
## User Clock
## -----------------------------------------------------------------------------
##		Bank:						14
##			VCCO:					1.8V (VCC1V8_FPGA)
##		Location:				U34 (SI570)
##			Vendor:				Silicon Labs
##			Device:				SI570BAB0000544DG
##			Frequency:		10 - 810 MHz, 50ppm
##			Default Freq:	156.250 MHz
##			I²C-Address:	0x5D #$ (0111 010xb)
set_property PACKAGE_PIN	AK34	[get_ports VC707_ProgUserClock_p]
set_property PACKAGE_PIN	AL34	[get_ports VC707_ProgUserClock_n]
# set I/O standard
set_property IOSTANDARD		LVDS	[get_ports -regexp {VC707_ProgUserClock_[p|n]}]
