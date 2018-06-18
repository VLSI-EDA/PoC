## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Nexys 4 DDR
## FPGA:          Xilinx Artix 7
##   Device:      XC7A100T
##   Package:     CSG324
##   Speedgrade:  -1
##
## =============================================================================================================================================================
## Bus Interface
## =============================================================================================================================================================
##
## Quad-SPI Flash
## -----------------------------------------------------------------------------
##  Bank:            
##    VCCO:          3.3V (VCC3V3)
##  Location:        
##    Vendor:        Spansion
##    Device:        S25FL128S
## -----------------------------------------------------------------------------
## {OUT}    CS#
set_property PACKAGE_PIN  L13       [ get_ports Nexys4DDR_QSPI_Flash_ChipSelect_n ]
## {INOUT}  SDI / DQ0
set_property PACKAGE_PIN  K17       [ get_ports Nexys4DDR_QSPI_Flash_Data[0] ]
## {INOUT}  SDO / DQ1
set_property PACKAGE_PIN  K17       [ get_ports Nexys4DDR_QSPI_Flash_Data[1] ]
## {INOUT}  WP# / DQ2
set_property PACKAGE_PIN  K17       [ get_ports Nexys4DDR_QSPI_Flash_Data[2] ]
## {INOUT}  HLD# / DQ3
set_property PACKAGE_PIN  K17       [ get_ports Nexys4DDR_QSPI_Flash_Data[3] ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4DDR_QSPI_Flash_.*} ]

# Ignore timings on async I/O pins
set_false_path                -to    [ get_ports -regexp {Nexys4DDR_QSPI_Flash_.*} ]
set_false_path                -from  [ get_ports -regexp {Nexys4DDR_QSPI_Flash_.*} ]
