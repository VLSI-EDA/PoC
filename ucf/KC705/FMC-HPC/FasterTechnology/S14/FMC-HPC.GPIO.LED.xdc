##
## FMC-HPC Interface for Faster Technologies S14 FMC Card
## -----------------------------------------------------------------------------
## General Purpose I/O - LED
## -----------------------------------------------------------------------------
## {OUT}	D1; LA19_n
set_property PACKAGE_PIN	F18				[ get_ports KC705_FMC_HPC_GPIO_LED[0] ]
## {OUT}	D2; LA19_p
set_property PACKAGE_PIN	G18				[ get_ports KC705_FMC_HPC_GPIO_LED[1] ]
## {OUT}	D3; LA18_n
set_property PACKAGE_PIN	E21				[ get_ports KC705_FMC_HPC_GPIO_LED[2] ]
## {OUT}	D4; LA18_p
set_property PACKAGE_PIN	F21				[ get_ports KC705_FMC_HPC_GPIO_LED[3] ]
# set I/O standard
set_property IOSTANDARD		LVCMOS25	[ get_ports -regexp {KC705_FMC_HPC_GPIO_LED\[[0-3]]} ]
# Ignore timings on async I/O pins
set_false_path									-to [ get_ports -regexp {KC705_FMC_HPC_GPIO_LED\[\d\]} ]

