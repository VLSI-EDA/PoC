## =============================================================================
## System Management Bus (SMBus)
## =============================================================================
##	Bank:						
##		VCCO:					
##	Location:				
##		Vendor:				
##		Device:				
## =============================================================================
if {$TimingConstraints == 0} then {
	# is it possible to define pin and I/O standard constraints here?
} else {
	# Ignore timings on async I/O pins
	set_false_path								-from	[get_ports DE4_SMBus_SerialClock]
	set_false_path								-to		[get_ports DE4_SMBus_SerialClock]
	set_false_path								-from	[get_ports DE4_SMBus_SerialData]
	set_false_path								-to		[get_ports DE4_SMBus_SerialData]
	set_false_path								-from	[get_ports DE4_SMBus_Alert]
}
