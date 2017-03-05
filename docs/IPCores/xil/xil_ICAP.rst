.. _IP:xil_ICAP:

PoC.xil.ICAP
############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/xil/xil_ICAP.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/xil/xil_ICAP_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <xil/xil_ICAP.vhdl>`
      * |gh-tb| :poctb:`Testbench <xil/xil_ICAP_tb.vhdl>`

This module wraps Xilinx "Internal Configuration Access Port" (ICAP) primitives in a generic
module. |br|
Supported devices are:
 * Spartan-6
 * Virtex-4, Virtex-5, Virtex-6
 * Series-7 (Artix-7, Kintex-7, Virtex-7, Zynq-7000)



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/xil/xil_ICAP.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 47-66



.. only:: latex

   Source file: :pocsrc:`xil/xil_ICAP.vhdl <xil/xil_ICAP.vhdl>`
