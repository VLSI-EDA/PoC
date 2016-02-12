##
## Pmod Port 1 (2x6 pins)
## -----------------------------------------------------------------------------
##	Bank:						10, 11
##		VCCO:					2.5V (VADJ)
##	Location:				J58
##	LevelShifted:		by U40 (TXS0108E) to 3.3V VCC3V3
## -----------------------------------------------------------------------------
## {INOUT}	Bank11	J58.1
set_property PACKAGE_PIN	AJ21				[get_ports ZC706_PMOD_Port1[0]]
## {INOUT}	Bank11	J58.3
set_property PACKAGE_PIN	AK21				[get_ports ZC706_PMOD_Port1[1]]
## {INOUT}	Bank11	J58.5
set_property PACKAGE_PIN	AB21				[get_ports ZC706_PMOD_Port1[2]]
## {INOUT}	Bank10	J58.6
set_property PACKAGE_PIN	AB16				[get_ports ZC706_PMOD_Port1[3]]
## {INOUT}	Bank9		J58.2
set_property PACKAGE_PIN	Y20 				[get_ports ZC706_PMOD_Port1[4]]
## {INOUT}	Bank9		J58.4
set_property PACKAGE_PIN	AA20				[get_ports ZC706_PMOD_Port1[5]]
## {INOUT}	Bank9		J58.6
set_property PACKAGE_PIN	AC18				[get_ports ZC706_PMOD_Port1[6]]
## {INOUT}	Bank9		J58.8
set_property PACKAGE_PIN	AC19				[get_ports ZC706_PMOD_Port1[7]]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[get_ports -regexp {ZC706_PMOD_Port1\[\d\]}]
# Ignore timings on async I/O pins
set_false_path									-to [get_ports -regexp {ZC706_PMOD_Port1\[\d\]}]
set_false_path								-from [get_ports -regexp {ZC706_PMOD_Port1\[\d\]}]
