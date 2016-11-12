
uart_fifo
#########

Small :abbr:`FIFO (first-in, first-out)` s are included in this module, if
larger or asynchronous transmit / receive FIFOs are required, then they must
be connected externally.

old comments:
  :abbr:`UART (Universal Asynchronous Receiver Transmitter)` BAUD rate generator
  bclk	    = bit clock is rising
  bclk_x8		= bit clock times 8 is rising




.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/uart/uart_fifo.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 52-94

Source file: `io/uart/uart_fifo.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/uart/uart_fifo.vhdl>`_



