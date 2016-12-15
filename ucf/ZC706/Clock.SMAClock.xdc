##	Bank:						9
##		VCCO:					2.5V (VADJ_FPGA)
##	Location:				J67, J68
set_property PACKAGE_PIN		AD18				[get_ports ZC706_SMAClock_p]
set_property PACKAGE_PIN		AD19				[get_ports ZC706_SMAClock_n]
# set I/O standard
set_property IOSTANDARD			LVDS_25				[get_ports -regexp {ZC706_SMAClock_.}]
