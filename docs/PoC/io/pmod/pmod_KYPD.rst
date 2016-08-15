
pmod_KYPD
#########

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

Source file: `io/pmod/pmod_KYPD.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/pmod/pmod_KYPD.vhdl>`_


	 