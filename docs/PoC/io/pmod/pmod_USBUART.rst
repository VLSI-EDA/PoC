
pmod_USBUART
############

This module abstracts a FTDI FT232R USB-UART bridge by instantiating a
:doc:`PoC.io.uart.fifo <../uart/uart_fifo>`. The FT232R supports up to
3 MBaud. A synchronous FIFO interface with a 32 words buffer is provided.
Hardware flow control (RTS_CTS) is enabled.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/pmod/pmod_USBUART.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 43-65

Source file: `io/pmod/pmod_USBUART.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/pmod/pmod_USBUART.vhdl>`_


	 