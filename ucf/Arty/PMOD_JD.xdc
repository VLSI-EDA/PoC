## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JD
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						35
##		VCCO:					3.3V (VCC3V3)
##	Location:					JD1,JD2,JD3,JD4,JD7,JD8,JD9,JD10
## -----------------------------------------------------------------------------

## {IN}			JD1
set_property PACKAGE_PIN  D4        [ get_ports Arty_PMOD_JD[1] ]  #IO_L11N_T1_SRCC_35
## {IN}			JD2                                         
set_property PACKAGE_PIN  D3        [ get_ports Arty_PMOD_JD[2] ]  #IO_L12N_T1_MRCC_35
## {IN}			JD3                                         
set_property PACKAGE_PIN  F4        [ get_ports Arty_PMOD_JD[3] ]  #IO_L13P_T2_MRCC_35
## {IN}			JD4                                         
set_property PACKAGE_PIN  F3        [ get_ports Arty_PMOD_JD[4] ]  #IO_L13N_T2_MRCC_35
## {IN}			JD7                                         
set_property PACKAGE_PIN  E2        [ get_ports Arty_PMOD_JD[7] ]  #IO_L14P_T2_SRCC_35
## {IN}			JD8                                         
set_property PACKAGE_PIN  D2        [ get_ports Arty_PMOD_JD[8] ]  #IO_L14N_T2_SRCC_35
## {IN}			JD9                                         
set_property PACKAGE_PIN  H2        [ get_ports Arty_PMOD_JD[9] ]  #IO_L15P_T2_DQS_35
## {IN}			JD10                                        
set_property PACKAGE_PIN  G2        [ get_ports Arty_PMOD_JD[10] ] #IO_L15N_T2_DQS_35

## -----------------------------------------------------------------------------

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_PMOD_JD[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_PMOD_JD[\d\]} ]

## -----------------------------------------------------------------------------