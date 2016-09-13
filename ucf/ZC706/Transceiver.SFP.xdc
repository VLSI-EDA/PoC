##
## Transceiver - SFP interface
## -----------------------------------------------------------------------------
##	Bank:						12, 15, 117
##		VCCO:					2.5V, 2.5V (VADJ_FPGA, VADJ_FPGA)
##		Quad117:
##			RefClock0
##			RefClock1		ZC706_SMA_RefClock
##		Placement:
##			SFP:				Quad117.Channel2 (GTXE2_CHANNEL_X0Y10)
##		Location:			P5
#$	##		I²C-Address:	0xA0 (1010 000xb)
## -----------------------------------------------------------------------------
## #$	; low-active; external 4k7 pullup resistor; level shifted by Q4 (NDS331N)
set_property PACKAGE_PIN		AA18				[get_ports ZC706_SFP_TX_Disable_n]
# set I/O standard
set_property IOSTANDARD		LVCMOS25		[get_ports ZC706_SFP_TX_Disable_n]
##
## --------------------------
## SFP+ LVDS signal-pairs
## {OUT}
set_property PACKAGE_PIN		W4				[get_ports ZC706_SFP_TX_p]
## {OUT}
set_property PACKAGE_PIN		W3				[get_ports ZC706_SFP_TX_n]
## {IN}
set_property PACKAGE_PIN		Y6				[get_ports ZC706_SFP_RX_p]
## {IN}
set_property PACKAGE_PIN		Y5				[get_ports ZC706_SFP_RX_n]

# Ignore timings on async I/O pins
set_false_path								-to		[get_ports ZC706_SFP_TX_Disable_n]


