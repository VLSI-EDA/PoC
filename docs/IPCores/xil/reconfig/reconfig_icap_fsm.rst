.. # Load pre-defined aliases from docutils
   # <file> is used to denote the special path
   # <Python>\Lib\site-packages\docutils\parsers\rst\include

.. include:: <mmlalias.txt>
.. include:: <isonum.txt>

.. _IP:reconfig_icap_fsm:

PoC.xil.reconfig.icap_fsm
#########################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/xil/reconfig/reconfig_icap_fsm.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/xil/reconfig/reconfig_icap_fsm_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <xil/reconfig/reconfig_icap_fsm.vhdl>`
      * |gh-tb| :poctb:`Testbench <xil/reconfig/reconfig_icap_fsm_tb.vhdl>`

This module parses the data stream to the Xilinx "Internal Configuration Access Port" (ICAP)
primitives to generate control signals. Tested on:

* Virtex-6
* Virtex-7



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/xil/reconfig/reconfig_icap_fsm.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 42-63



.. only:: latex

   Source file: :pocsrc:`xil/reconfig/reconfig_icap_fsm.vhdl <xil/reconfig/reconfig_icap_fsm.vhdl>`
