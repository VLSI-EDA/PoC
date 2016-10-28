
sdram_ctrl_s3esk
################

Controller for Micron DDR-SDRAM on Spartan-3E Starter Kit Board.
SDRAM Device: MT46V32M16-6T

CLK_PERIOD = clock period in nano seconds. All SDRAM timings are
calculated for the device stated above.

CL = cas latency, choose according to clock frequency.
BL = burst length.

Tested with: CLK_PERIOD = 10.0, CL=2, BL=2.

Command, address and write data is sampled with clk.

Read data is aligned with clk_fb90_n. Either process data in this clock
domain, or connect a FIFO to transfer data into another clock domain of your
choice.  This FIFO should capable of storing at least one burst (size BL/2)
+ start of next burst (size 1).

Synchronous resets are used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/sdram/sdram_ctrl_s3esk.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 76-119

Source file: `mem/sdram/sdram_ctrl_s3esk.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/sdram/sdram_ctrl_s3esk.vhdl>`_



