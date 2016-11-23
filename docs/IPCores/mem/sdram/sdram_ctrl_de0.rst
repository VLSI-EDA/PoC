.. _IP:sdram_ctrl_de0:

PoC.mem.sdram.ctrl_de0
######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/sdram/sdram_ctrl_de0.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/sdram/sdram_ctrl_de0_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/sdram/sdram_ctrl_de0.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/sdram/sdram_ctrl_de0_tb.vhdl>`

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
:ref:`sdram_ctrl_phy_de0 <IP:sdram_ctrl_phy_de0>`.

Synchronous resets are used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/sdram/sdram_ctrl_de0.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 68-100



.. only:: latex

   Source file: :pocsrc:`mem/sdram/sdram_ctrl_de0.vhdl <mem/sdram/sdram_ctrl_de0.vhdl>`
