.. _IP:io_7SegmentMux_HEX:

PoC.io.7SegmentMux_HEX
######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_7SegmentMux_HEX.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/io_7SegmentMux_HEX_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/io_7SegmentMux_HEX.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/io_7SegmentMux_HEX_tb.vhdl>`

This module is a 7 segment display controller that uses time multiplexing
to control a common anode for each digit in the display. The shown characters
are HEX encoded. A dot per digit is optional.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_7SegmentMux_HEX.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 45-60



.. only:: latex

   Source file: :pocsrc:`io/io_7SegmentMux_HEX.vhdl <io/io_7SegmentMux_HEX.vhdl>`
