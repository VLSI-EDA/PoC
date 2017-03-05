.. _IP:io_KeyPadScanner:

PoC.io.KeyPadScanner
####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_KeyPadScanner.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/io_KeyPadScanner_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/io_KeyPadScanner.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/io_KeyPadScanner_tb.vhdl>`

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



.. only:: latex

   Source file: :pocsrc:`io/io_KeyPadScanner.vhdl <io/io_KeyPadScanner.vhdl>`
