
ocram_sdp
#########

Inferring / instantiating simple dual-port memory, with:

* dual clock, clock enable,
* 1 read port plus 1 write port.

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

Mixed-Port Read-During-Write
  When reading at the write address, the read value will be unknown which is
  aka. "don't care behavior". This applies to all reads (at the same
  address) which are issued during the write-cycle time, which starts at the
  rising-edge of the write clock and (in the worst case) extends until the
  next rising-edge of the write clock.

.. WARNING::
   The simulated behavior on RT-level is too optimistic. The
   mixed-port read-during-write behavior is only valid if the read and write
   clock are in phase. Otherwise, simulation will always show known data.

.. TODO:: Implement correct behavior for RT-level simulation.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_sdp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 65-82

Source file: `mem/ocram/ocram_sdp.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sdp.vhdl>`_



