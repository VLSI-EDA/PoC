
sdram_ctrl_de0
##############

Complete controller for ISSI SDR-SDRAM for Altera DE0 Board.

SDRAM Device: IS42S16400F

Configuration
*************

+------------+----------------------------------------------------+
| Parameter  | Description                                        |
+============+====================================================+
| CLK_PERIOD | Clock period in nano seconds. All SDRAM timings are|
|            | calculated for the device stated above.            |
+------------+----------------------------------------------------+
| CL         | CAS latency, choose according to clock frequency.  |
+------------+----------------------------------------------------+
| BL         | Burst length. Choose BL=1 for single cycle memory  |
|            | transactions as required for the PoC.Mem interface.|
+------------+----------------------------------------------------+

Tested with: CLK_PERIOD = 7.5 (133 MHz), CL=2, BL=1.

Operation
*********

Command, address and write data is sampled with ``clk``.
Read data is also aligned with ``clk``.

For description on ``clkout`` see
:doc:`sdram_ctrl_phy_de0 <sdram_ctrl_phy_de0>`.

Synchronous resets are used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/sdram/sdram_ctrl_de0.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 88-120

Source file: `mem/sdram/sdram_ctrl_de0.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/sdram/sdram_ctrl_de0.vhdl>`_



