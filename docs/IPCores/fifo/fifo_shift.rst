.. _IP:fifo_shift:

PoC.fifo.shift
##############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/fifo/fifo_shift.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/fifo/fifo_shift_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <fifo/fifo_shift.vhdl>`
      * |gh-tb| :poctb:`Testbench <fifo/fifo_shift_tb.vhdl>`

This FIFO implementation is based on an internal shift register. This is
especially useful for smaller FIFO sizes, which can be implemented in LUT
storage on some devices (e.g. Xilinx' SRLs). Only a single read pointer is
maintained, which determines the number of valid entries within the
underlying shift register.

The specified depth (``MIN_DEPTH``) is rounded up to the next suitable value.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/fifo/fifo_shift.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 44-64



.. only:: latex

   Source file: :pocsrc:`fifo/fifo_shift.vhdl <fifo/fifo_shift.vhdl>`
