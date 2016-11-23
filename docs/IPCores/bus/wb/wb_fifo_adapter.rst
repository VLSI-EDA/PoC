.. _IP:wb_fifo_adapter:

PoC.bus.wb.fifo_adapter
#######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/bus/wb/wb_fifo_adapter.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/bus/wb/wb_fifo_adapter_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <bus/wb/wb_fifo_adapter.vhdl>`
      * |gh-tb| :poctb:`Testbench <bus/wb/wb_fifo_adapter_tb.vhdl>`

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



.. only:: latex

   Source file: :pocsrc:`bus/wb/wb_fifo_adapter.vhdl <bus/wb/wb_fifo_adapter.vhdl>`
