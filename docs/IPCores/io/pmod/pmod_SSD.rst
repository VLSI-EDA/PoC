.. _IP:pmod_SSD:

PoC.io.pmod.SSD
###############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/pmod/pmod_SSD.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/pmod/pmod_SSD_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/pmod/pmod_SSD.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/pmod/pmod_SSD_tb.vhdl>`

This module drives a dual-digit 7-segment display (Pmod_SSD). The module
expects two binary encoded 4-bit ``Digit<i>`` signals and drives a 2x6 bit
Pmod connector (7 anode bits, 1 cathode bit).

.. code-block:: none

   Segment Pos./ Index
      AAA      |   000
     F   B     |  5   1
     F   B     |  5   1
      GGG      |   666
     E   C     |  4   2
     E   C     |  4   2
      DDD  DOT |   333  7



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/pmod/pmod_SSD.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 56-69



.. only:: latex

   Source file: :pocsrc:`io/pmod/pmod_SSD.vhdl <io/pmod/pmod_SSD.vhdl>`
