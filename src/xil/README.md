# Namespace `PoC.xil`

The namespace `PoC.xil` offers Xilinx specific implementations and abstractions
for various devices families.

## Subnamespace

  - [`mig`][xil.mig] Xilinx specific pre-configured memory controllers from Xilinx Memory Interface Generator (MIG).

## Package

The package [`PoC.xil`][xil.pkg] holds all component declarations for this namespace.


## Entities

 -  [`xil_BSCAN`][xil_BSCAN] abstracts the *boundary scan* (JTAG) primitive of
    the following FPGA families:
     -  Spartan-3, Spartan-6
     -  Virtex-5, Virtex-6
     -  7-Series FPGAs.
 -  [`xil_ChipScopeICON`][xil_ChipScopeICON] abstracts the ChipScope Integrated
    Controller (ICON) for 1 to 15 control ports. PoC provides 15 pre-configured
		IP core files (*.xco) to generate 15 netlists for all port counts.
     -  [`xil_ChipScopeICON_1`][xil_ChipScopeICON_1] - pre-configure netlist file for 1 port
     -  [`xil_ChipScopeICON_2`][xil_ChipScopeICON_2] - pre-configure netlist file for 2 ports
     -  [`xil_ChipScopeICON_3`][xil_ChipScopeICON_3] - pre-configure netlist file for 3 ports
     -  [`xil_ChipScopeICON_4`][xil_ChipScopeICON_4] - pre-configure netlist file for 4 ports
     -  [`xil_ChipScopeICON_5`][xil_ChipScopeICON_5] - pre-configure netlist file for 5 ports
     -  [`xil_ChipScopeICON_6`][xil_ChipScopeICON_6] - pre-configure netlist file for 6 ports
     -  [`xil_ChipScopeICON_7`][xil_ChipScopeICON_7] - pre-configure netlist file for 7 ports
     -  [`xil_ChipScopeICON_8`][xil_ChipScopeICON_8] - pre-configure netlist file for 8 ports
     -  [`xil_ChipScopeICON_9`][xil_ChipScopeICON_9] - pre-configure netlist file for 9 ports
     -  [`xil_ChipScopeICON_10`][xil_ChipScopeICON_10] - pre-configure netlist file for 10 ports
     -  [`xil_ChipScopeICON_11`][xil_ChipScopeICON_11] - pre-configure netlist file for 11 ports
     -  [`xil_ChipScopeICON_12`][xil_ChipScopeICON_12] - pre-configure netlist file for 12 ports
     -  [`xil_ChipScopeICON_13`][xil_ChipScopeICON_13] - pre-configure netlist file for 13 ports
     -  [`xil_ChipScopeICON_14`][xil_ChipScopeICON_14] - pre-configure netlist file for 14 ports
     -  [`xil_ChipScopeICON_15`][xil_ChipScopeICON_15] - pre-configure netlist file for 15 ports
 -  [`xil_Reconfigurator`][xil_Reconfigurator] implements generic reconfiguration
    module for the DRP bus, used by many Xilinx primitives like PLLs, DCMs or MGTs.
 -  [`xil_SystemMonitor_Virtex6`][xil_SystemMonitor_Virtex6] - abstracts the
    Virtex-6 system monitor to measure the FPGA's temperature.
 -  [`xil_SystemMonitor_Series7`][xil_SystemMonitor_Series7] - abstracts the
    7-Series XADC primitive to measure the FPGA's temperature.

 [xil.mig]:							mig

 [xil.pkg]:							xil.pkg.vhdl

 [xil_BSCAN]:						xil_BSCAN.vhdl
 [xil_ChipScopeICON]:				xil_ChipScopeICON.vhdl
 [xil_ChipScopeICON_1]:				xil_ChipScopeICON_1.vhdl
 [xil_ChipScopeICON_2]:				xil_ChipScopeICON_2.vhdl
 [xil_ChipScopeICON_3]:				xil_ChipScopeICON_3.vhdl
 [xil_ChipScopeICON_4]:				xil_ChipScopeICON_4.vhdl
 [xil_ChipScopeICON_5]:				xil_ChipScopeICON_5.vhdl
 [xil_ChipScopeICON_6]:				xil_ChipScopeICON_6.vhdl
 [xil_ChipScopeICON_7]:				xil_ChipScopeICON_7.vhdl
 [xil_ChipScopeICON_8]:				xil_ChipScopeICON_8.vhdl
 [xil_ChipScopeICON_9]:				xil_ChipScopeICON_9.vhdl
 [xil_ChipScopeICON_10]:			xil_ChipScopeICON_10.vhdl
 [xil_ChipScopeICON_11]:			xil_ChipScopeICON_11.vhdl
 [xil_ChipScopeICON_12]:			xil_ChipScopeICON_12.vhdl
 [xil_ChipScopeICON_13]:			xil_ChipScopeICON_13.vhdl
 [xil_ChipScopeICON_14]:			xil_ChipScopeICON_14.vhdl
 [xil_ChipScopeICON_15]:			xil_ChipScopeICON_15.vhdl
 [xil_Reconfigurator]:				xil_Reconfigurator.vhdl
 [xil_SystemMonitor_Virtex6]:	xil_SystemMonitor_Virtex6.vhdl
 [xil_SystemMonitor_Series7]:	xil_SystemMonitor_Series7.vhdl
