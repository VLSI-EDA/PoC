
comm_scramble
#############

The LFSR computation is unrolled to generate an arbitrary number of mask
bits in parallel. The mask are output in little endian. The generated bit
sequence is independent from the chosen output width.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/comm/comm_scramble.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 37-51

Source file: `comm/comm_scramble.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/comm/comm_scramble.vhdl>`_


	 