.. _IP:pmod_KYPD:

PoC.io.pmod.KYPD
################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/pmod/pmod_KYPD.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/pmod/pmod_KYPD_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/pmod/pmod_KYPD.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/pmod/pmod_KYPD_tb.vhdl>`

This module drives a 4-bit one-cold encoded column vector to read back a
4-bit rows vector. By scanning column-by-column it's possible to extract
the current button state of the whole keypad. This wrapper converts the
high-active signals from :doc:`PoC.io.KeypadScanner <../io_KeyPadScanner>`
to low-active signals for the pmod. An additional debounce circuit filters
the button signals. The scan frequency and bounce time can be configured.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/pmod/pmod_KYPD.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 46-61



.. only:: latex

   Source file: :pocsrc:`io/pmod/pmod_KYPD.vhdl <io/pmod/pmod_KYPD.vhdl>`
