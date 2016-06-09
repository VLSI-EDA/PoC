
fifo_shift
##########

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

Source file: `fifo/fifo_shift.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/fifo/fifo_shift.vhdl>`_


	 