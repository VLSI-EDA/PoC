##
## FMC-LPC Interface for Faster Technologies S14 FMC Card
## -----------------------------------------------------------------------------
##  Bank:            12, 117
##    VCCO:          2.5V (VADJ_FPGA)
##    Quad117:
##      RefClock0:  
##      RefClock1    
##    Placement:
##      SFP:         Quad117.Channel3 (GTXE2_CHANNEL_X0Y11)
##    Location:      J2
## -----------------------------------------------------------------------------
## I2C interface
## {INOUT}  LA05_n
set_property PACKAGE_PIN    AH22    [ get_ports KC705_FMC_LPC_SFP_SerialClock[3] ]
## {INOUT}  LA06_p
set_property PACKAGE_PIN    AK20    [ get_ports KC705_FMC_LPC_SFP_SerialData[3] ]
##
## SFP+ LVDS signal-pairs
## {OUT}    DP0_C2M_P
set_property PACKAGE_PIN    F2      [ get_ports KC705_FMC_LPC_SFP_TX_p[3] ]
## {OUT}    DP0_C2M_N
set_property PACKAGE_PIN    F1      [ get_ports KC705_FMC_LPC_SFP_TX_n[3] ]
## {IN}     DP0_M2C_P
set_property PACKAGE_PIN    F6      [ get_ports KC705_FMC_LPC_SFP_RX_p[3] ]
## {IN}     DP0_M2C_N
set_property PACKAGE_PIN    F5      [ get_ports KC705_FMC_LPC_SFP_RX_n[3] ]

# Ignore timings on async I/O pins
set_false_path                -to   [ get_ports KC705_FMC_LPC_SFP_TX_Disable_n ]
set_false_path                -from [ get_ports KC705_FMC_LPC_SFP_LossOfSignal ]