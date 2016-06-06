
wb_fifo_adapter
###############

Small FIFOs are included in this module, if larger or asynchronous
transmit / receive FIFOs are required, then they must be connected
externally.

old comments:
	 UART BAUD rate generator
	 bclk_r    = bit clock is rising
	 bclk_x8_r = bit clock times 8 is rising



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/bus/wb/wb_fifo_adapter.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 80-104


	 