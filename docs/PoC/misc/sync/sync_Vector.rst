
sync_Vector
###########

	This module synchronizes a vector of bits from clock-domain 'Clock1' to
	clock-domain 'Clock2'. The clock-domain boundary crossing is done by a
	change comparator, a T-FF, two synchronizer D-FFs and a reconstructive
	XOR indicating a value change on the input. This changed signal is used
	to capture the input for the new output. A busy flag is additionally
	calculated for the input clock domain.
	CONSTRAINTS:
		General:
			This module uses sub modules which need to be constrainted. Please
			attend to the notes of the instantiated sub modules.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/sync/sync_Vector.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 50-64

Source file: `misc/sync/sync_Vector.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/sync/sync_Vector.vhdl>`_


 
