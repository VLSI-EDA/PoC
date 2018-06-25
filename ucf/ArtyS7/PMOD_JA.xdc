## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty_S7
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JA
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						14
##		VCCO:					3.3V (VCC3V3)
##	Location:					JA1_P,JA1_N,JA2_P,JA2_N,JA3_P,JA3_N,JA4_P,JA4_N
## -----------------------------------------------------------------------------

## {IN}			JA1_P
set_property PACKAGE_PIN  L17        [ get_ports Arty_S7_PMOD_JA[1]_P]  #IO_L4P_T0_D04_14
## {IN}			JA1_N                                         
set_property PACKAGE_PIN  L18        [ get_ports Arty_S7_PMOD_JA[1]_N]  #IO_L4N_T0_D05_14
## {IN}			JA2_P                                        
set_property PACKAGE_PIN  M14        [ get_ports Arty_S7_PMOD_JA[2]_P]  #IO_L5P_T0_D06_14
## {IN}			JA2_N                                        
set_property PACKAGE_PIN  N14        [ get_ports Arty_S7_PMOD_JA[2]_N]  #IO_L5N_T0_D07_14
## {IN}			JA3_P                                          
set_property PACKAGE_PIN  M16        [ get_ports Arty_S7_PMOD_JA[3]_P]  #IO_L7P_T1_D09_14
## {IN}			JA3_N                                          
set_property PACKAGE_PIN  M17        [ get_ports Arty_S7_PMOD_JA[3]_N]  #IO_L7N_T1_D10_14
## {IN}			JA4_P                                          
set_property PACKAGE_PIN  M18        [ get_ports Arty_S7_PMOD_JA[4]_P]  #IO_L8P_T1_D11_14
## {IN}			JA4_N                                         
set_property PACKAGE_PIN  N18        [ get_ports Arty_S7_PMOD_JA[4]_N ] #IO_L8N_T1_D12_14


## -----------------------------------------------------------------------------

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {Arty_S7_PMOD_JA[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {Arty_S7_PMOD_JA[\d\]} ]

## -----------------------------------------------------------------------------