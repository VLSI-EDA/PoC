
ocram_sp
########

Inferring / instantiating enhanced single port memory, with:

* single clock, clock enable,
* 1 read/write port.

When writing data, the read output will be unknown which is aka. "don't
care behavior". The read output will be unknown for the full write-cycle
time, which starts at the rising-edge of the clock and (in the worst case)
extends until the next rising-edge of the clock.

.. WARNING::
   The simulated behavior on RT-level is too optimistic. During a
   write, always the new data will be returned as read value.

.. TODO:: Implement correct behavior for RT-level simulation.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_sp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 59-73

Source file: `mem/ocram/ocram_sp.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sp.vhdl>`_



