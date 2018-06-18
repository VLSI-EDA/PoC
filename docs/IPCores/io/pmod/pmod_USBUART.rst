.. _IP:pmod_USBUART:

PoC.io.pmod.USBUART
###################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/pmod/pmod_USBUART.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/pmod/pmod_USBUART_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/pmod/pmod_USBUART.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/pmod/pmod_USBUART_tb.vhdl>`

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



.. only:: latex

   Source file: :pocsrc:`io/pmod/pmod_USBUART.vhdl <io/pmod/pmod_USBUART.vhdl>`
