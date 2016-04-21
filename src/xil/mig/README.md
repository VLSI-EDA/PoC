# Namespace `PoC.xil.mig`

The namespace `PoC.xil.mig` offers pre-configured memory controllers generated
with Xilinx's Memory Interface Generator (MIG).


## Entities

  - for Spartan-6 boards:
      - [`mig_Atlys_1x128`][mig_Atlys_1x128] A DDR2 memory controller for the Digilent Atlys board.  
        Run PoC's [netlist compiler][netlist] tool twice:
         1. Generate the source files from the IP core using Xilinx MIG and afterwards patch them  
            `PS> .\netlist.ps1 --coregen PoC.xil.mig.Atlys_1x128.1 -l --board Atlys`
         2. Compile the patched sources into a ready to use netlist (\*.ngc) and constraint file (\*.ucf)    
            `PS> .\netlist.ps1 --xst PoC.xil.mig.Atlys_1x128.2 -l --board Atlys`
  - for Kintex-7 boards:
      - ...
  - for Virtex-7 boards:
      - ...

 [mig.pkg]:				mig.pkg.vhdl

 [mig_Atlys_1x128]:		mig_Atlys_1x128.xco

 [netlist]:				../../../netlist
