##
## I2C-MainBus
## -----------------------------------------------------------------------------
##	Bank:						10
##		VCCO:					2.5V (VCC2V5_FPGA)
##	Location:				U65 (PCA9548ARGER)
##		Vendor:				Texas Instruments
##		Device:				PCA9548A-RGER - 8-Channel I2C Switch with Reset
##		I2C-Address:	0x74 (0111 010xb)
## -----------------------------------------------------------------------------
##	Devices:				8
##		Channel 0:		Programmable UserClock and SFP cage
##			Location:			U37										/ P2
##			Vendor:				Silicon Labs
##			Device:				Si570
##			Address:			0xBA (1011 101xb)			/ 0xA0 (1010 000xb)
##		Channel 1:		ADV7511 HDMI
##			Location:			U53
##			Address:			0x72 (0111 001xb)
##		Channel 2:		M24C08 I2C EEPROM
##			Location:			U9
##			Address:			0xA8 (1010 100xb)
##		Channel 3:		I2C Port Expander
##			Location:			U16
##			Vendor:
##			Device:
##			Address:			0x42 (0100 001xb)
##			Channel 0:			DDR3 SODIMM J1
##				Address:				0xA0, 0x30 (1010 000xb, 0011 000xb)
##		Channel 4:		I2C Real Time Clock			/ Si5324
##			Location:			U26										/ U60 (SI5324-C-GM)
##			Vendor:															/ Silicon Labs
##			Device:															/ SI5324 - Any-Frequency Precision Clock Multiplier/Jitter Attenuator
##			Address:			0xA2 (1010 001xb)			/ 0xD0 (1101 000xb)
##		Channel 5:		FMC HPC
##			Location:
##			Vendor:
##			Device:
##			Address:
##		Channel 6:		FMX LPC
##			Location:
##			Address:
##		Channel 7:		UCD90120A (PMbus)
##			Location:			U48
##			Address:			0xCA (1100 101xb)
## -----------------------------------------------------------------------------
## {INOUT}	U65 - Pin 19 - SerialClock; level shifted by U87 (PCA9517)
set_property PACKAGE_PIN		AJ14				[get_ports ZC706_IIC_SerialClock]
## {INOUT}	U49 - Pin 20 - SerialData; level shifted by U87 (PCA9517)
set_property PACKAGE_PIN		AJ18				[get_ports ZC706_IIC_SerialData]
## {OUT}		#$	U49 - Pin 24 - Reset (low-active); ; level shifted by U25 (TXS0102)
##set_property PACKAGE_PIN		F20				[get_ports ZC706_IIC_Switch_Reset_n]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {ZC706_IIC_.*}]

# Ignore timings on async I/O pins
set_false_path								-to		[get_ports -regexp {ZC706_IIC_.*}]
set_false_path								-from	[get_ports -regexp {ZC706_IIC_Serial.*}]
