.. _IP:uart_wb:

PoC.bus.wb.uart_wrapper
#######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/bus/wb/wb_uart_wrapper.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/bus/wb/wb_uart_wrapper_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <bus/wb/wb_uart_wrapper.vhdl>`
      * |gh-tb| :poctb:`Testbench <bus/wb/wb_uart_wrapper_tb.vhdl>`

Wrapper module for :doc:`PoC.io.uart.rx </IPCores/io/uart/uart_rx>` and
:doc:`PoC.io.uart.tx </IPCores/io/uart/uart_tx>` to support the Wishbone
interface. Synchronized reset is used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/bus/wb/wb_uart_wrapper.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 40-69



.. only:: latex

   Source file: :pocsrc:`bus/wb/wb_uart_wrapper.vhdl <bus/wb/wb_uart_wrapper.vhdl>`
