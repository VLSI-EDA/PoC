.. _IP:uart_fifo:

PoC.io.uart.fifo
################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/uart/uart_fifo.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/uart/uart_fifo_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/uart/uart_fifo.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/uart/uart_fifo_tb.vhdl>`

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



.. only:: latex

   Source file: :pocsrc:`io/uart/uart_fifo.vhdl <io/uart/uart_fifo.vhdl>`
