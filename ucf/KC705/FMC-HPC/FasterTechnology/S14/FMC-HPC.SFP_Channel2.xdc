##
## FMC-HPC Interface for Faster Technologies S14 FMC Card
## -----------------------------------------------------------------------------
##  Bank:            12, 118
##    VCCO:          2.5V (VADJ_FPGA)
##    Quad117:
##      RefClock0:  
##      RefClock1    
##    Placement:
##      SFP:        Quad118.Channel1 (GTXE2_CHANNEL_X0Y10)
##    Location:      J2
## -----------------------------------------------------------------------------
## I2C interface
## {INOUT}  LA09_p
set_property PACKAGE_PIN    B30     [ get_ports KC705_FMC_HPC_SFP_SerialClock[2}]
## {INOUT}  LA09_n
set_property PACKAGE_PIN    A30     [ get_ports KC705_FMC_HPC_SFP_SerialData[2] ]

##
## SFP+ LVDS signal-pairs
## {OUT}    DP1_C2M_P
set_property PACKAGE_PIN    C4      [ get_ports KC705_FMC_HPC_SFP_TX_p[2] ]
## {OUT}    DP1_C2M_N
set_property PACKAGE_PIN    C3      [ get_ports KC705_FMC_HPC_SFP_TX_n[2] ]
## {IN}     DP1_M2C_P
set_property PACKAGE_PIN    D6      [ get_ports KC705_FMC_HPC_SFP_RX_p[2] ]
## {IN}     DP1_M2C_N
set_property PACKAGE_PIN    D5      [ get_ports KC705_FMC_HPC_SFP_RX_n[2] ]

# Ignore timings on async I/O pins
set_false_path                -to   [ get_ports -regexp {KC705_FMC_HPC_SFP_Serial.*} ]
set_false_path                -from [ get_ports -regexp {KC705_FMC_HPC_SFP_Serial.*} ]
