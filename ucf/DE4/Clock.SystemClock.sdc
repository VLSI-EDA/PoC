## =============================================================================
## Clocks
## =============================================================================
##
## System Clock
## =============================================================================
##		Bank:						
##			VCCO:					
##		Location:				
##			Vendor:				
##			Device:				
##			Frequency:		100 MHz
if {$TimingConstraints == 0} then {
	# is it possible to define pin and I/O standard constraints here?
} else {
  ## specify a 100 MHz clock
	create_clock -name NET_SystemClock_100MHz -period 10.000 -waveform {0.000 5.000} [get_ports DE4_SystemClock_100MHz]
}
