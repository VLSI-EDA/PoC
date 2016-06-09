
io_TimingCounter
################

	This down-counter can be configured with a TIMING_TABLE (a ROM), from which
	the initial counter value is loaded. The table index can be selected by
	'Slot'. 'Timeout' is a registered output. Up to 16 values fit into one ROM
	consisting of 'log2ceilnz(imax(TIMING_TABLE)) + 1' 6-input LUTs.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/io/io_TimingCounter.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 43-54

Source file: `io/io_TimingCounter.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/io_TimingCounter.vhdl>`_


	 