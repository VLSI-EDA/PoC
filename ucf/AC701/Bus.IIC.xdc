##
## I2C-MainBus
## -----------------------------------------------------------------------------
##	Bank:						14
##		VCCO:					3.3V (FPGA_3V3)
##	Location:				U52 (PCA9548ARGER)
##		Vendor:				Texas Instruments
##		Device:				PCA9548A-RGER - 8-Channel I2C Switch with Reset
##		I2C-Address:	0x74 (0111 010xb)
## -----------------------------------------------------------------------------
##	Devices:				8
##		Channel 0:		Programmable UserClock
##			Location:			U34
##			Vendor:				Silicon Labs
##			Device:				Si570
##			Address:			0xBA (1011 101xb)
##		Channel 1:		FMC Connector 1 (HPC)
##			Location:
##		Channel 2:		unused
##		Channel 3:		EEPROM
##			Location:			U6
##			Vendor:
##			Device:				M24C08
##			Address:			0xA8 (1010 100xb)
##		Channel 4:		SFP cage
##			Location:			P3
##			Address:			0xA0 (1010 000xb)
##		Channel 5:		HDMI
##			Location:
##			Vendor:
##			Device:
##			Address:			0x72 (0111 001xb)
##		Channel 6:		DDR3
##			Location:
##			Address:			0xA0, 0x30 (1010 000xb, 0011 000xb)
##		Channel 7:		SI5324
##			Location:			U?? (SI5324-C-GM)
##			Vendor:				Silicon Labs
##			Device:				SI5324 - Any-Frequency Precision Clock Multiplier/Jitter Attenuator
##			Address:			0xD0 (1101 000xb)
## -----------------------------------------------------------------------------
## {INOUT}	U52 - Pin 19 - SerialClock
set_property PACKAGE_PIN		N18				[get_ports AC701_IIC_SerialClock]
## {INOUT}	U52 - Pin 20 - SerialData
set_property PACKAGE_PIN		K25				[get_ports AC701_IIC_SerialData]
## {OUT}		#$	U52 - Pin 24 - Reset (low-active)
set_property PACKAGE_PIN		R17				[get_ports AC701_IIC_Switch_Reset_n]
# set I/O standard
set_property IOSTANDARD			LVCMOS33	[get_ports -regexp {AC701_IIC_.*}]

# Ignore timings on async I/O pins
set_false_path								-to		[get_ports -regexp {AC701_IIC_.*}]
set_false_path								-from	[get_ports -regexp {AC701_IIC_Serial.*}]
