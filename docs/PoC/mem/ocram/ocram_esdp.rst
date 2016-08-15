
ocram_esdp
##########

Inferring / instantiating enhanced simple dual-port memory, with:

* dual clock, clock enable,
* 1 read/write port (1st port) plus 1 read port (2nd port).

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

* Same-Port Read-During Write:
  At rising edge of "clk1", data "d1" written to port 1 (ce1 and we1 = '1')
  is directly passed to the output "q1". This is also known as write-first
  mode or read-through write behavior.

* Mixed-Port Read-During Write:
  Here, the Altera M512/M4K TriMatrix memory (as found e.g. in Stratix
  and Stratix II FPGAs) defines the minimum time after which the written data
  at port 1 can be read-out at port 2 again. As stated in the Stratix
  Handbook, Volume 2, page 2-13, data is actually written with the falling
  (instead of the rising) edge of the clock into the memory array. The write
  itself takes the write-cycle time which is less or equal to the minimum
  clock-period time. After this, the data can be read-out at the other port.
  Consequently, data "d1" written at the rising-edge of "clk1" at address
  "a1" can be read-out at the 2nd port from the same address with the
  2nd rising-edge of "clk2" following the falling-edge of "clk1".
  If the rising-edge of "clk2" coincides with the falling-edge of "clk1"
  (e.g. same clock signal), then it is counted as the 1st rising-edge of
  "clk2" in this timing.

WARNING: The simulated behavior on RT-level is not correct.

TODO: add timing diagram
TODO: implement correct behavior for RT-level simulation



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_esdp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 78-96

Source file: `mem/ocram/ocram_esdp.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_esdp.vhdl>`_


	 