
ocram_esdp
##########

Inferring / instantiating enhanced simple dual-port memory, with:

* dual clock, clock enable,
* 1 read/write port (1st port) plus 1 read port (2nd port).

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

Same-Port Read-During Write
  When writing data through port 1, the read output of the same port (``q1``)
  will be unknown which is aka. "don't care behavior". The read output will
  be unknown for the full write-cycle time, which starts at the
  rising-edge of the clock of port 1 (``clk1``) and (in the worst case)
  extends until the next rising-edge of that clock.

Mixed-Port Read During Write
  When reading at the write address, the read value will be unknown which is
  aka. "don't care behavior". This applies to all reads (at the same
  address) which are issued during the write-cycle time, which starts at the
  rising-edge of the write clock (``clk1``) and (in the worst case) extends
  until the next rising-edge of the write clock.

.. WARNING::
   The simulated behavior on RT-level is too optimistic. When reading
   at the write address always the new data will be returned.

.. TODO:: Implement correct behavior for RT-level simulation.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_esdp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 73-91

Source file: `mem/ocram/ocram_esdp.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_esdp.vhdl>`_



