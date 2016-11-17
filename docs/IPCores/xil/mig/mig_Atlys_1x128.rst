.. _IP:mig_Atlys_1x128:

mig_Atlys_1x128
###############

This DDR2 memory controller is pre-configured for the Digilent Atlys development
board. The board is equipped with a single 1 GiBit DDR2 memory chip (128 MiByte)
from MIRA (MIRA P3R1GE3EGF G8E DDR2).

Run the following two steps to create the IP core:

1. Generate the source files from the IP core using Xilinx MIG and afterwards patch them |br|
   ``PS> .\poc.ps1 coregen PoC.xil.mig.Atlys_1x128 --board=Atlys``

2. Compile the patched sources into a ready to use netlist (\*.ngc) and constraint file (\*.ucf) |br|
   ``PS> .\poc.ps1 xst PoC.xil.mig.Atlys_1x128 --board=Atlys``

.. seealso::
   :doc:`Using PoC -> Synthesis </UsingPoC/Synthesis>`
     For how to run Core Generator and XST from PoC.
