## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty_S7
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JC
## =============================================================================================================================================================
## -------------------------------------------------------------------------------------------------------------
##	Bank:						14,CONFIG
##		VCCO:					3.3V (VCC3V3)
##	Location:					JC[1]/CK_IO[41],JC[2]/CK_IO[40],JC[3]/CK_IO[39],JC[4]/CK_IO[38],JC[7]/CK_IO[37],
								JC[8]/CK_IO[36],JC[9]/CK_IO[35],JC[10]/CK_IO[34]
## -------------------------------------------------------------------------------------------------------------

## {IN}			JC[1]/CK_IO[41]
set_property PACKAGE_PIN  U15        [ get_ports Arty_PMOD_JC[1]/CK_IO[41] ]  #IO_L18P_T2_A12_D28_14
## {IN}			JC[2]/CK_IO[40]                                       
set_property PACKAGE_PIN  V16        [ get_ports Arty_PMOD_JC[2]/CK_IO[40] ]  #IO_L18N_T2_A11_D27_14
## {IN}			JC[3]/CK_IO[39]                                       
set_property PACKAGE_PIN  U17        [ get_ports Arty_PMOD_JC[3]/CK_IO[39] ]  #IO_L15P_T2_DQS_RDWR_B_14
## {IN}			JC[4]/CK_IO[38]                                        
set_property PACKAGE_PIN  U18        [ get_ports Arty_PMOD_JC[4]/CK_IO[38] ]  #IO_L15N_T2_DQS_DOUT_CSO_B_14
## {IN}			JC[7]/CK_IO[37]                                       
set_property PACKAGE_PIN  U16        [ get_ports Arty_PMOD_JC[7]/CK_IO[37] ]  #IO_L16P_T2_CSI_B_14
## {IN}			JC[8]/CK_IO[36]                                       
set_property PACKAGE_PIN  P13        [ get_ports Arty_PMOD_JC[8]/CK_IO[36] ]  #IO_L19P_T3_A10_D26_14
## {IN}			JC[9]/CK_IO[35]                                        
set_property PACKAGE_PIN  R13        [ get_ports Arty_PMOD_JC[9]/CK_IO[35] ]  #IO_L19N_T3_A09_D25_VREF_14
## {IN}			JC[10]/CK_IO[34]                                        
set_property PACKAGE_PIN  V14        [ get_ports Arty_PMOD_JC[10]/CK_IO[34] ] #IO_L20P_T3_A08_D24_14

## -------------------------------------------------------------------------------------------------------------

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_S7_PMOD_JC[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_S7_PMOD_JC[\d\]} ]

## -------------------------------------------------------------------------------------------------------------