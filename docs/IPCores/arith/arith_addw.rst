
arith_addw
##########

	Implements wide addition providing several options all based
	on an adaptation of a carry-select approach.

	References:
		* Hong Diep Nguyen and Bogdan Pasca and Thomas B. Preusser:
			FPGA-Specific Arithmetic Optimizations of Short-Latency Adders,
			FPL 2011.
			-> ARCH:     AAM, CAI, CCA
			-> SKIPPING: CCC

		* Marcin Rogawski, Kris Gaj and Ekawat Homsirikamol:
			A Novel Modular Adder for One Thousand Bits and More
			Using Fast Carry Chains of Modern FPGAs, FPL 2014.
			-> ARCH:		 PAI
			-> SKIPPING: PPN_KS, PPN_BK



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_addw.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 53-70

Source file: `arith/arith_addw.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_addw.vhdl>`_



