
xil_ChipScopeICON
#################

This module wraps 15 ChipScope ICON IP core netlists generated from ChipScope
ICON xco files. The generic parameter ``PORTS`` selects the apropriate ICON
instance with 1 to 15 ICON ``ControlBus`` ports. Each ``ControlBus`` port is
of type ``T_XIL_CHIPSCOPE_CONTROL`` and of mode ``inout``.
..rubric:: Compile required CoreGenerator IP Cores to Netlists with PoC:

Please use the provided netlist compile command in PoC to recreate the needed
source and netlist files on your local machine.

.. code-block:: vhdl
 
   cd <PoCRoot>
   .\poc.ps1 coregen PoC.xil.ChipScopeICON_1 --board=KC705
   [...]
   .\poc.ps1 coregen PoC.xil.ChipScopeICON_15 --board=KC705


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/xil/xil_ChipScopeICON.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 58-65

Source file: `xil/xil_ChipScopeICON.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_ChipScopeICON.vhdl>`_

.. seealso::
 
   :doc:`Using PoC -> Synthesis </UsingPoC/Synthesis>`
     For how to run synthesis with PoC and CoreGenerator.
 

 
