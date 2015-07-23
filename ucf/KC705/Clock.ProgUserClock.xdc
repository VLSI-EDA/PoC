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
## User Clock
## -----------------------------------------------------------------------------
##		Bank:						15
##			VCCO:					2.5V (VCC2V5_FPGA)
##		Location:				U45 (SI570)
##			Vendor:				Silicon Labs
##			Device:				SI570BAB0000544DG
##			Frequency:		10 - 810 MHz, 50ppm
##			Default Freq:	156.250 MHz
##			I²C-Address:	0x5D #$ (0111 010xb)
set_property PACKAGE_PIN	K28			[get_ports KC705_ProgUserClock_p]
set_property PACKAGE_PIN	K29			[get_ports KC705_ProgUserClock_n]
# set I/O standard
set_property IOSTANDARD		LVDS_25	[get_ports -regexp {KC705_ProgUserClock_[p|n]}]
#$ NET "KC705_ProgUserClock_p"				TNM_NET = "NET_ProgUserClock";
