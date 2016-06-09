
pmod_USBUART
############

	This module abstracts a FTDI FT232R USB-UART bridge. The FT232R supports
	up to 3 MBaud. A synchronous FIFO interface (32x words) is provided.
	Hardware flow control (RTS_CTS) is enabled.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/pmod/pmod_USBUART.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 42-64

Source file: `io/pmod/pmod_USBUART.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/pmod/pmod_USBUART.vhdl>`_


	 