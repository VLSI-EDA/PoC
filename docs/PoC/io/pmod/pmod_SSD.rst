
pmod_SSD
########

	This module drives a dual-digit 7-segment display (Pmod_SSD). The module
	expects two binary encoded 4-bit 'Digit<i>' signals and drives a 2x6 bit
	Pmod connector (7 anode bits, 1 cathode bit).
	Segment Pos./ Index
		 AAA      |   000
		F   B     |  5   1
		F   B     |  5   1
		 GGG      |   666
		E   C     |  4   2
		E   C     |  4   2
		 DDD  DOT |   333  7


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/pmod/pmod_SSD.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 54-67

Source file: `io/pmod/pmod_SSD.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/pmod/pmod_SSD.vhdl>`_


	 