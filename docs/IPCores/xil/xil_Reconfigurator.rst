.. _IP:xil_Reconfigurator:

PoC.xil.Reconfigurator
######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_Reconfigurator.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/xil/xil_Reconfigurator_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <xil/xil_Reconfigurator.vhdl>`
      * |gh-tb| :poctb:`Testbench <xil/xil_Reconfigurator_tb.vhdl>`

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



.. only:: latex

   Source file: :pocsrc:`xil/xil_Reconfigurator.vhdl <xil/xil_Reconfigurator.vhdl>`
