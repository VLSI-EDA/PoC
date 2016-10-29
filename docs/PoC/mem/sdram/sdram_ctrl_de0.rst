
sdram_ctrl_de0
##############

Complete controller for ISSI SDR-SDRAM for Altera DE0 Board.
SDRAM Device: IS42S16400F

CLK_PERIOD = clock period in nano seconds. All SDRAM timings are
calculated for the device stated above.

CL = cas latency, choose according to clock frequency.
BL = burst length.

Command, address and write data is sampled with clk.

Tested with: CLK_PERIOD = 7.5 (133 MHz), CL=2, BL=1.

Read data is aligned with clk. Either process data in this clock
domain, or connect a FIFO to transfer data into another clock domain of your
choice.

For description on 'clkout' see sdram_ctrl_phy_de0.vhdl.

Synchronous resets are used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/sdram/sdram_ctrl_de0.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 77-109

Source file: `mem/sdram/sdram_ctrl_de0.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/sdram/sdram_ctrl_de0.vhdl>`_



