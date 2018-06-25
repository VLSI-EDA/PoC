## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty_S7
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JB
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						14
##		VCCO:					3.3V (VCC3V3)
##	Location:					JB1_P,JB1_N,JB2_P,JB2_N,JB3_P,JB3_N,JB4_P,JB4_N
## -----------------------------------------------------------------------------

## {IN}			JB1_P
set_property PACKAGE_PIN  P17        [ get_ports Arty_PMOD_JB[1]_P ] #IO_L9P_T1_DQS_14
## {IN}			JB1_N
set_property PACKAGE_PIN  P18        [ get_ports Arty_PMOD_JB[1]_N ] #IO_L9N_T1_DQS_D13_14
## {IN}			JB2_P
set_property PACKAGE_PIN  R18        [ get_ports Arty_PMOD_JB[2]_P ] #IO_L10P_T1_D14_14
## {IN}			JB2_N
set_property PACKAGE_PIN  T18        [ get_ports Arty_PMOD_JB[2]_N ] #IO_L10N_T1_D15_14
## {IN}			JB3_P
set_property PACKAGE_PIN  P14        [ get_ports Arty_PMOD_JB[3]_P ] #IO_L11P_T1_SRCC_14
## {IN}			JB3_N
set_property PACKAGE_PIN  P15        [ get_ports Arty_PMOD_JB[3]_N ] #IO_L11N_T1_SRCC_14
## {IN}			JB4_P
set_property PACKAGE_PIN  N15        [ get_ports Arty_PMOD_JB[4]_P ] #IO_L12P_T1_MRCC_14
## {IN}			JB4_N
set_property PACKAGE_PIN  P16        [ get_ports Arty_PMOD_JB[4]_N ] #IO_L12N_T1_MRCC_14

## -----------------------------------------------------------------------------

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_S7_PMOD_JB[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_S7_PMOD_JB[\d\]} ]

## -----------------------------------------------------------------------------