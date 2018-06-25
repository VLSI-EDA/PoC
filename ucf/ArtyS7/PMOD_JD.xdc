## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty_S7
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JD
## =============================================================================================================================================================
## -------------------------------------------------------------------------------------------------------------
##	Bank:						14
##		VCCO:					3.3V (VCC3V3)
##	Location:					JD[1]/CK_IO[33],JD[2]/CK_IO[32],JD[3]/CK_IO[31],JD[4]/CK_IO[30],JD[7]/CK_IO[29],
								JD[8]/CK_IO[28],JD[9]/CK_IO[27],JD[10]/CK_IO[26]
## -------------------------------------------------------------------------------------------------------------

## {IN}			JD[1]/CK_IO[33]
set_property PACKAGE_PIN  V15        [ get_ports Arty_PMOD_JD[1]/CK_IO[33] ]  #IO_L20N_T3_A07_D23_14
## {IN}			JD[2]/CK_IO[32]                                       
set_property PACKAGE_PIN  U12        [ get_ports Arty_PMOD_JD[2]/CK_IO[32] ]  #IO_L21P_T3_DQS_14
## {IN}			JD[3]/CK_IO[31]                                       
set_property PACKAGE_PIN  V13        [ get_ports Arty_PMOD_JD[3]/CK_IO[31] ]  #IO_L21N_T3_DQS_A06_D22_14
## {IN}			JD[4]/CK_IO[30]                                        
set_property PACKAGE_PIN  T12        [ get_ports Arty_PMOD_JD[4]/CK_IO[30] ]  #IO_L22P_T3_A05_D21_14
## {IN}			JD[7]/CK_IO[29]                                       
set_property PACKAGE_PIN  T13        [ get_ports Arty_PMOD_JD[7]/CK_IO[29] ]  #IO_L22N_T3_A04_D20_14
## {IN}			JD[8]/CK_IO[28]                                       
set_property PACKAGE_PIN  R11        [ get_ports Arty_PMOD_JD[8]/CK_IO[28] ]  #IO_L23P_T3_A03_D19_14
## {IN}			JD[9]/CK_IO[27]                                        
set_property PACKAGE_PIN  T11        [ get_ports Arty_PMOD_JD[9]/CK_IO[27] ]  #IO_L23N_T3_A02_D18_14
## {IN}			JD[10]/CK_IO[26]                                        
set_property PACKAGE_PIN  U11        [ get_ports Arty_PMOD_JD[10]/CK_IO[26] ] #IO_L24P_T3_A01_D17_14

## -------------------------------------------------------------------------------------------------------------

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_S7_PMOD_JD[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_S7_PMOD_JD[\d\]} ]

## -------------------------------------------------------------------------------------------------------------