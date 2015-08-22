##
## Fan Control
## =============================================================================
##	Bank:						15
##		VCCO:					1,8V (VCC1V8_FPGA)
##	Location:				J48, Q1
## -----------------------------------------------------------------------------
if {$TimingConstraints == 0} then {
	# is it possible to define pin and I/O standard constraints here?
} else {
	# Ignore timings on async I/O pins
	set_false_path								-to		[get_ports DE4_FanControl]
}
