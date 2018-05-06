##
## FMC-HPC Interface for Faster Technologies S14 FMC Card
## -----------------------------------------------------------------------------
##  Bank:            12, 118
##    VCCO:          2.5V (VADJ_FPGA)
##    Quad117:
##      RefClock0:  
##      RefClock1    
##    Placement:
##      SFP:        Quad118.Channel2 (GTXE2_CHANNEL_X0Y10)
##    Location:      J2
## -----------------------------------------------------------------------------
## I2C interface
## {INOUT}  LA12_n
set_property PACKAGE_PIN    B29     [ get_ports KC705_FMC_HPC_SFP_SerialClock[1}]
## {INOUT}  LA13_p
set_property PACKAGE_PIN    A25     [ get_ports KC705_FMC_HPC_SFP_SerialData[1] ]

##
## SFP+ LVDS signal-pairs
## {OUT}    DP2_C2M_P
set_property PACKAGE_PIN    B2      [ get_ports KC705_FMC_HPC_SFP_TX_p[1] ]
## {OUT}    DP2_C2M_N
set_property PACKAGE_PIN    B1      [ get_ports KC705_FMC_HPC_SFP_TX_n[1] ]
## {IN}     DP2_M2C_P
set_property PACKAGE_PIN    B6      [ get_ports KC705_FMC_HPC_SFP_RX_p[1] ]
## {IN}     DP2_M2C_N
set_property PACKAGE_PIN    B5      [ get_ports KC705_FMC_HPC_SFP_RX_n[1] ]

# Ignore timings on async I/O pins
set_false_path                -to   [ get_ports -regexp {KC705_FMC_HPC_SFP_Serial.*} ]
set_false_path                -from [ get_ports -regexp {KC705_FMC_HPC_SFP_Serial.*} ]
