
gearbox_up_dc
#############

	This module provides a upscaling gearbox with a dependent clock (dc)
	interface. It perfoems a 'byte' to 'word' collection. The default order is
	LITTLE_ENDIAN (starting at byte(0)). Input "In_Data" is of clock domain
	"Clock1"; output "Out_Data" is of clock domain "Clock2". The "In_Align"
	is required to mark the starting byte in the word. An optional input
	register can be added by enabling (ADD_INPUT_REGISTERS = TRUE).

Assertions:
===========
	- Clock periods of Clock1 and Clock2 MUST be multiples of each other.
	- Clock1 and Clock2 MUST be phase aligned (related) to each other.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/gearbox/gearbox_up_dc.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 51-66

Source file: `misc/gearbox/gearbox_up_dc.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/gearbox/gearbox_up_dc.vhdl>`_


	 