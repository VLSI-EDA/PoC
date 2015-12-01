## User Clock
## -----------------------------------------------------------------------------
##		Bank:						10
##			VCCO:					2.5V (VADJ_FPGA)
##		Location:				U37 (SI570)
##			Vendor:				Silicon Labs
##			Device:				SI570BAB0000544DG
##			Frequency:		10 - 810 MHz, 50ppm
##			Default Freq:	156.250 MHz
##			I²C-Address:	
set_property PACKAGE_PIN	AF14			[get_ports ZC706_ProgUserClock_p]
set_property PACKAGE_PIN	AG14			[get_ports ZC706_ProgUserClock_n]
# set I/O standard
set_property IOSTANDARD		LVDS_25	[get_ports -regexp {ZC706_ProgUserClock_[p|n]}]
#$ NET "ZC706_ProgUserClock_p"				TNM_NET = "NET_ProgUserClock";
