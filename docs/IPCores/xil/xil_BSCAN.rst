.. _IP:xil_BSCAN:

PoC.xil.BSCAN
#############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_BSCAN.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/xil/xil_BSCAN_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <xil/xil_BSCAN.vhdl>`
      * |gh-tb| :poctb:`Testbench <xil/xil_BSCAN_tb.vhdl>`

This module wraps Xilinx "Boundary Scan" (JTAG) primitives in a generic
module. |br|
Supported devices are:
 * Spartan-3, Spartan-6
 * Virtex-5, Virtex-6
 * Series-7 (Artix-7, Kintex-7, Virtex-7, Zynq-7000)



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/xil/xil_BSCAN.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 47-65



.. only:: latex

   Source file: :pocsrc:`xil/xil_BSCAN.vhdl <xil/xil_BSCAN.vhdl>`
