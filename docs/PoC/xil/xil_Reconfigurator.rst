
xil_Reconfigurator
##################

Many complex primitives in a Xilinx device offer a Dynamic Reconfiguration
Port (DRP) to reconfigure a primitive at runtime without reconfiguring the
whole FPGA.

This module is a DRP master that can be pre-configured at compile time with
different configuration sets. The configuration sets are mapped into a ROM.
The user can select a stored configuration with ``ConfigSelect``. Sending a
strobe to ``Reconfig`` will start the reconfiguration process. The operation
completes with another strobe on ``ReconfigDone``.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/xil/xil_Reconfigurator.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 51-72

Source file: `xil/xil_Reconfigurator.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_Reconfigurator.vhdl>`_


 
