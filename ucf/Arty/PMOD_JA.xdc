## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JA
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						15
##		VCCO:					3.3V (VCC3V3)
##	Location:					JA1,JA2,JA3,JA4,JA7,JA8,JA9,JA10
## -----------------------------------------------------------------------------

## {IN}			JA1
set_property PACKAGE_PIN  G13        [ get_ports Arty_PMOD_JA[1] ]  #IO_0_15
## {IN}			JA2
set_property PACKAGE_PIN  B11        [ get_ports Arty_PMOD_JA[2] ]  #IO_L4P_T0_15
## {IN}			JA3
set_property PACKAGE_PIN  A11        [ get_ports Arty_PMOD_JA[3] ]  #IO_L4N_T0_15
## {IN}			JA4
set_property PACKAGE_PIN  D12        [ get_ports Arty_PMOD_JA[4] ]  #IO_L6P_T0_15
## {IN}			JA7
set_property PACKAGE_PIN  D13        [ get_ports Arty_PMOD_JA[7] ]  #IO_L6N_T0_VREF_15
## {IN}			JA8
set_property PACKAGE_PIN  B18        [ get_ports Arty_PMOD_JA[8] ]  #IO_L10P_T1_AD11P_15
## {IN}			JA9
set_property PACKAGE_PIN  A18        [ get_ports Arty_PMOD_JA[9] ]  #IO_L10P_T1_AD11N_15
## {IN}			JA10
set_property PACKAGE_PIN  K16        [ get_ports Arty_PMOD_JA[10] ] #IO_25_15

## -----------------------------------------------------------------------------

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_PMOD_JA[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_PMOD_JA[\d\]} ]

## -----------------------------------------------------------------------------