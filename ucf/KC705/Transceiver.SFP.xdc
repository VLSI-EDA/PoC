##
## Transceiver - SFP interface
## -----------------------------------------------------------------------------
##	Bank:						12, 15, 117
##		VCCO:					2.5V, 2.5V (VADJ_FPGA, VADJ_FPGA)
##		Quad117:
##			RefClock0
##			RefClock1		KC705_SMA_RefClock
##		Placement:
##			SFP:				Quad117.Channel2 (GTXE2_CHANNEL_X0Y10)
##		Location:			P5
#$	##		I2C-Address:	0xA0 (1010 000xb)
## -----------------------------------------------------------------------------
## #$	; low-active; external 4k7 pullup resistor; level shifted by Q4 (NDS331N)
set_property PACKAGE_PIN		Y20				[get_ports KC705_SFP_TX_Disable_n]
## #$	; high-active; external 4k7 pullup resistor; level shifted by U69 (SN74AVC1T45)
set_property PACKAGE_PIN		P19				[get_ports KC705_SFP_LossOfSignal]
# set I/O standard
set_property IOSTANDARD		LVCMOS25		[get_ports KC705_SFP_TX_Disable_n]
set_property IOSTANDARD		LVCMOS25		[get_ports KC705_SFP_LossOfSignal]
##
## --------------------------
## SFP+ LVDS signal-pairs
## {OUT}
set_property PACKAGE_PIN		H2				[get_ports KC705_SFP_TX_p]
## {OUT}
set_property PACKAGE_PIN		H1				[get_ports KC705_SFP_TX_n]
## {IN}
set_property PACKAGE_PIN		G4				[get_ports KC705_SFP_RX_p]
## {IN}
set_property PACKAGE_PIN		G3				[get_ports KC705_SFP_RX_n]

# Ignore timings on async I/O pins
set_false_path								-to		[get_ports KC705_SFP_TX_Disable_n]
set_false_path								-from	[get_ports KC705_SFP_LossOfSignal]


