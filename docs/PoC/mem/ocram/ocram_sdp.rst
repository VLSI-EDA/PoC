
ocram_sdp
#########

Inferring / instantiating simple dual-port memory, with:
	* dual clock, clock enable,
	* 1 read port plus 1 write port.

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

  The Altera M512/M4K TriMatrix memory (as found e.g. in Stratix and
  Stratix II FPGAs) defines the minimum time after which the written data at
  the write port can be read-out at read port again. As stated in the Stratix
  Handbook, Volume 2, page 2-13, data is actually written with the falling
  (instead of the rising) edge of the clock into the memory array. The write
  itself takes the write-cycle time which is less or equal to the minimum
  clock-period time. After this, the data can be read-out at the other port.
  Consequently, data "d" written at the rising-edge of "wclk" at address
  "wa" can be read-out at the read port from the same address with the
  2nd rising-edge of "rclk" following the falling-edge of "wclk".
  If the rising-edge of "rclk" coincides with the falling-edge of "wclk"
  (e.g. same clock signal), then it is counted as the 1st rising-edge of
  "rclk" in this timing.

WARNING: The simulated behavior on RT-level is not correct.

TODO: add timing diagram
TODO: implement correct behavior for RT-level simulation



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_sdp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 69-86

Source file: `mem/ocram/ocram_sdp.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sdp.vhdl>`_



