## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JC
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						14
##		VCCO:					3.3V (VCC3V3)
##	Location:					JC1_P,JC1_N,JC2_P,JC2_N,JC3_P,JC3_N,JC4_P,JC4_N
## -----------------------------------------------------------------------------

## {IN}			JC1_P
set_property PACKAGE_PIN  U12        [ get_ports Arty_PMOD_JC[1]_P ] #IO_L20P_T3_A08_D24_14
## {IN}			JC1_N                                        
set_property PACKAGE_PIN  V12        [ get_ports Arty_PMOD_JC[1]_N ] #IO_L20N_T3_A07_D23_14
## {IN}			JC2_P                                        
set_property PACKAGE_PIN  V10        [ get_ports Arty_PMOD_JC[2]_P ] #IO_L21P_T3_DQS_14
## {IN}			JC2_N                                        
set_property PACKAGE_PIN  V11        [ get_ports Arty_PMOD_JC[2]_N ] #IO_L21N_T3_DQS_A06_D22_14
## {IN}			JC3_P                                        
set_property PACKAGE_PIN  U14        [ get_ports Arty_PMOD_JC[3]_P ] #IO_L22P_T3_A05_D21_14
## {IN}			JC3_N                                        
set_property PACKAGE_PIN  V14        [ get_ports Arty_PMOD_JC[3]_N ] #IO_L22N_T3_A04_D20_14
## {IN}			JC4_P                                        
set_property PACKAGE_PIN  T13        [ get_ports Arty_PMOD_JC[4]_P ] #IO_L23P_T3_A03_D19_14
## {IN}			JC4_N                                        
set_property PACKAGE_PIN  U13        [ get_ports Arty_PMOD_JC[4]_N ] #IO_L23N_T3_A02_D18_14

## -----------------------------------------------------------------------------

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_PMOD_JC[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_PMOD_JC[\d\]} ]

## -----------------------------------------------------------------------------