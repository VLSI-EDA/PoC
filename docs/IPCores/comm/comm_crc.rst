.. _IP:comm_crc:

PoC.comm.crc
############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/comm/comm_crc.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/comm/comm_crc_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <comm/comm_crc.vhdl>`
      * |gh-tb| :poctb:`Testbench <comm/comm_crc_tb.vhdl>`

Computes the Cyclic Redundancy Check (CRC) for a data packet as remainder
of the polynomial division of the message by the given generator
polynomial (GEN).

The computation is unrolled so as to process an arbitrary number of
message bits per step. The generated CRC is independent from the chosen
processing width.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/comm/comm_crc.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 45-64



.. only:: latex

   Source file: :pocsrc:`comm/comm_crc.vhdl <comm/comm_crc.vhdl>`
