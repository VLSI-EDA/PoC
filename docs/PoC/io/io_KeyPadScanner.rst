
io_KeyPadScanner
################

	This module drives a one-hot encoded column vector to read back a rows
	vector. By scanning column-by-column it's possible to extract the current
	button state of the whole keypad. The scanner uses high-active logic. The
	keypad size and scan frequency can be configured. The outputed signal
	matrix is not debounced.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_KeyPadScanner.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 46-63

Source file: `io/io_KeyPadScanner.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_KeyPadScanner.vhdl>`_


 
