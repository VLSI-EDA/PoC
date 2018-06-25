## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JB
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						15
##		VCCO:					3.3V (VCC3V3)
##	Location:					JB1_P,JB1_N,JB2_P,JB2_N,JB3_P,JB3_N,JB4_P,JB4_N
## -----------------------------------------------------------------------------

## {IN}			JB1_P
set_property PACKAGE_PIN  E15        [ get_ports Arty_PMOD_JB[1]_P ] #IO_L11P_T1_SRCC_15
## {IN}			JB1_N
set_property PACKAGE_PIN  E16        [ get_ports Arty_PMOD_JB[1]_N ] #IO_L11N_T1_SRCC_15
## {IN}			JB2_P
set_property PACKAGE_PIN  D15        [ get_ports Arty_PMOD_JB[2]_P ] #IO_L12P_T1_MRCC_15
## {IN}			JB2_N
set_property PACKAGE_PIN  C15        [ get_ports Arty_PMOD_JB[2]_N ] #IO_L12N_T1_MRCC_15
## {IN}			JB3_P
set_property PACKAGE_PIN  J17        [ get_ports Arty_PMOD_JB[3]_P ] #IO_L23P_T3_FOE_B_15
## {IN}			JB3_N
set_property PACKAGE_PIN  J18        [ get_ports Arty_PMOD_JB[3]_N ] #IO_L23N_T3_FWE_B_15
## {IN}			JB4_P
set_property PACKAGE_PIN  K15        [ get_ports Arty_PMOD_JB[4]_P ] #IO_L24P_T3_RS1_15
## {IN}			JB4_N
set_property PACKAGE_PIN  J15        [ get_ports Arty_PMOD_JB[4]_N ] #IO_L24N_T3_RS0_15

## -----------------------------------------------------------------------------

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_PMOD_JB[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_PMOD_JB[\d\]} ]

## -----------------------------------------------------------------------------