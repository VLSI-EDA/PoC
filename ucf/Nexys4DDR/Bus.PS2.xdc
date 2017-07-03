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
## General Purpose I/O
## =============================================================================================================================================================
##
## PS2 - USB HID host controller emulating PS2
## -----------------------------------------------------------------------------
##  Bank:            
##    VCCO:          3.3V (VCC3V3)
##  Location:        
##    Vendor:        
##    Device:        PIC24FJ128
## -----------------------------------------------------------------------------
## {INOUT}  SerialClock
set_property PACKAGE_PIN  K21       [ get_ports Nexys4DDR_PS2_SerialClock ]
## {INOUT}  SerialData
set_property PACKAGE_PIN  L21       [ get_ports Nexys4DDR_PS2_SerialData ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Nexys4DDR_PS2_Serial.*} ]

# Ignore timings on async I/O pins
set_false_path                -to    [ get_ports -regexp {Nexys4DDR_PS2_Serial.*} ]
set_false_path                -from  [ get_ports -regexp {Nexys4DDR_PS2_Serial.*} ]
