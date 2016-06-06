
io_7SegmentMux_BCD
##################

	This module is a 7 segment display controller that uses time multiplexing
	to control a common anode for each digit in the display. The shown characters
	are BCD encoded. A dot per digit is optional. A minus sign for negative
	numbers is supported.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_7SegmentMux_BCD.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 45-60


	 