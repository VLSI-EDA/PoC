.. _IP:mig_KC705_MT8JTF12864HZ_1G6:

mig_KC705_MT8JTF12864HZ_1G6
###########################

This DDR2 memory controller is pre-configured for the Xilinx KC705 development
board. The board is equipped with a single 1 GiBit DDR3 memory chip (128 MiByte)
from Micron Technology (MT8JTF12864HZ-1G6G1).

Run the following two steps to create the IP core:

1. Generate the source files from the IP core using Xilinx MIG and afterwards patch them |br|
   ``PS> .\poc.ps1 coregen PoC.xil.mig.KC705_MT8JTF12864HZ_1G6 --board=KC705``

2. Compile the patched sources into a ready to use netlist (\*.ngc) and constraint file (\*.ucf) |br|
   ``PS> .\poc.ps1 xst PoC.xil.mig.KC705_MT8JTF12864HZ_1G6 --board=KC705``

.. seealso::
   :doc:`Using PoC -> Synthesis </UsingPoC/Synthesis>`
     For how to run Core Generator and XST from PoC.

