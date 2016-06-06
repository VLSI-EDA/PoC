
mig
===

The namespace ``PoC.xil.mig`` offers pre-configured memory controllers generated
with Xilinx's Memory Interface Generator (MIG).

* **for Spartan-6 boards:**

  * :doc:`mig_Atlys_1x128 </PoC/xil/mig/mig_Atlys_1x128>` A DDR2 memory controller for the Digilent Atlys board. |br|
    Run PoC's :doc:`synthesis flow </UsingPoC/Synthesis>` twice:
    
    1. Generate the source files from the IP core using Xilinx MIG and afterwards patch them |br|
       ``PS> .\poc.ps1 coregen PoC.xil.mig.Atlys_1x128 --board=Atlys``
    
    2. Compile the patched sources into a ready to use netlist (\*.ngc) and constraint file (\*.ucf) |br|
       ``PS> .\poc.ps1 xst PoC.xil.mig.Atlys_1x128 --board=Atlys``

  * **for Kintex-7 boards:**
    
    * :doc:`mig_KC705_MT8JTF12864HZ_1G6 </PoC/xil/mig/mig_KC705_MT8JTF12864HZ_1G6>` A DDR3 memory controller for the Xilinx KC705 board. |br|
      Run PoC's :doc:`synthesis flow </UsingPoC/Synthesis>` twice:
    
    1. Generate the source files from the IP core using Xilinx MIG and afterwards patch them |br|
       ``PS> .\poc.ps1 coregen PoC.xil.mig.KC705_MT8JTF12864HZ_1G6 --board=KC705``
    
    2. Compile the patched sources into a ready to use netlist (\*.ngc) and constraint file (\*.ucf) |br|
       ``PS> .\poc.ps1 xst PoC.xil.mig.KC705_MT8JTF12864HZ_1G6 --board=KC705``
  
  * **for Virtex-7 boards:**


.. toctree::
   :hidden:
   
   mig_Atlys_1x128
   mig_KC705_MT8JTF12864HZ_1G6
