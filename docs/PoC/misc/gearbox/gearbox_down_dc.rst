
gearbox_down_dc
###############

This module provides a downscaling gearbox with a dependent clock (dc)
interface. It perfoems a 'word' to 'byte' splitting. The default order is
LITTLE_ENDIAN (starting at byte(0)). Input "In_Data" is of clock domain
"Clock1"; output "Out_Data" is of clock domain "Clock2". Optional input and
output registers can be added by enabling (ADD_***PUT_REGISTERS = TRUE).
Assertions:
===========
- Clock periods of Clock1 and Clock2 MUST be multiples of each other.
- Clock1 and Clock2 MUST be phase aligned (related) to each other.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/misc/gearbox/gearbox_down_dc.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 50-64

Source file: `misc/gearbox/gearbox_down_dc.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/misc/gearbox/gearbox_down_dc.vhdl>`_


	 