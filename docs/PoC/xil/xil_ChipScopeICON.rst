
xil_ChipScopeICON
#################

This module wraps 15 ChipScope ICON IP core netlists generated from ChipScope
ICON xco files. The generic parameter ``PORTS`` selects the apropriate ICON
instance with 1 to 15 ICON ``ControlBus`` ports. Each ``ControlBus`` port is
of type ``T_XIL_CHIPSCOPE_CONTROL`` and of mode ``inout``.

.. rubric:: Compile required CoreGenerator IP Cores to Netlists with PoC

Please use the provided Xilinx ISE compile command ``ise`` in PoC to recreate
the needed source and netlist files on your local machine.

.. code-block:: PowerShell

   cd PoCRoot
   .\poc.ps1 ise PoC.xil.ChipScopeICON --board=KC705



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/xil/xil_ChipScopeICON.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 56-63

Source file: `xil/xil_ChipScopeICON.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_ChipScopeICON.vhdl>`_

.. seealso::
   
   :doc:`Using PoC -> Synthesis </UsingPoC/Synthesis>`
     For how to run synthesis with PoC and CoreGenerator.
   

	 