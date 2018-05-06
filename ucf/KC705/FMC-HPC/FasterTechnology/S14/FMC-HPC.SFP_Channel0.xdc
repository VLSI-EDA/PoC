##
## FMC-HPC Interface for Faster Technologies S14 FMC Card
## -----------------------------------------------------------------------------
##  Bank:            12, 118
##    VCCO:          2.5V (VADJ_FPGA)
##    Quad117:
##      RefClock0:  
##      RefClock1    
##    Placement:
##      SFP:        Quad118.Channel3 (GTXE2_CHANNEL_X0Y10)
##    Location:      J2
## -----------------------------------------------------------------------------
## I2C interface
## {INOUT}  LA16_p
set_property PACKAGE_PIN    B27     [ get_ports KC705_FMC_HPC_SFP_SerialClock[0}]
## {INOUT}  LA16_n
set_property PACKAGE_PIN    A27     [ get_ports KC705_FMC_HPC_SFP_SerialData[0] ]

##
## SFP+ LVDS signal-pairs
## {OUT}    DP3_C2M_P
set_property PACKAGE_PIN    A4      [ get_ports KC705_FMC_HPC_SFP_TX_p[0] ]
## {OUT}    DP3_C2M_N
set_property PACKAGE_PIN    A3      [ get_ports KC705_FMC_HPC_SFP_TX_n[0] ]
## {IN}     DP3_M2C_P
set_property PACKAGE_PIN    A8      [ get_ports KC705_FMC_HPC_SFP_RX_p[0] ]
## {IN}     DP3_M2C_N
set_property PACKAGE_PIN    A7      [ get_ports KC705_FMC_HPC_SFP_RX_n[0] ]

# Ignore timings on async I/O pins
set_false_path                -to   [ get_ports -regexp {KC705_FMC_HPC_SFP_Serial.*} ]
set_false_path                -from [ get_ports -regexp {KC705_FMC_HPC_SFP_Serial.*} ]
