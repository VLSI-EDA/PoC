##
## FMC-HPC Interface for Faster Technologies S14 FMC Card
## -----------------------------------------------------------------------------
##  Bank:            12, 118
##    VCCO:          2.5V (VADJ_FPGA)
##    Quad117:
##      RefClock0:  
##      RefClock1    
##    Placement:
##      SFP:        Quad117.Channel0 (GTXE2_CHANNEL_X0Y10)
##    Location:      J2
## -----------------------------------------------------------------------------
## I2C interface
## {INOUT}  LA05_n
set_property PACKAGE_PIN    F30     [ get_ports KC705_FMC_HPC_SFP_SerialClock[3}]
## {INOUT}  LA06_p
set_property PACKAGE_PIN    H30     [ get_ports KC705_FMC_HPC_SFP_SerialData[3] ]

##
## SFP+ LVDS signal-pairs
## {OUT}    DP0_C2M_P
set_property PACKAGE_PIN    D2      [ get_ports KC705_FMC_HPC_SFP_TX_p[3] ]
## {OUT}    DP0_C2M_N
set_property PACKAGE_PIN    D1      [ get_ports KC705_FMC_HPC_SFP_TX_n[3] ]
## {IN}     DP0_M2C_P
set_property PACKAGE_PIN    E4      [ get_ports KC705_FMC_HPC_SFP_RX_p[3] ]
## {IN}     DP0_M2C_N
set_property PACKAGE_PIN    E3      [ get_ports KC705_FMC_HPC_SFP_RX_n[3] ]

# Ignore timings on async I/O pins
set_false_path                -to   [ get_ports -regexp {KC705_FMC_HPC_SFP_Serial.*} ]
set_false_path                -from [ get_ports -regexp {KC705_FMC_HPC_SFP_Serial.*} ]
