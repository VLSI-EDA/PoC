.. _IP:sdram_ctrl_s3esk:

PoC.mem.sdram.ctrl_s3esk
########################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/sdram/sdram_ctrl_s3esk.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/sdram/sdram_ctrl_s3esk_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/sdram/sdram_ctrl_s3esk.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/sdram/sdram_ctrl_s3esk_tb.vhdl>`

Controller for Micron DDR-SDRAM on Spartan-3E Starter Kit Board.

SDRAM Device: MT46V32M16-6T

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
| BL         | Burst length. Choose BL=2 for single cycle memory  |
|            | transactions as required for the PoC.Mem interface.|
+------------+----------------------------------------------------+

Tested with: CLK_PERIOD = 10.0, CL=2, BL=2.

Operation
*********

Command, address and write data are sampled with the rising edge of ``clk``.

Read data is aligned with ``clk_fb90_n``. Either process data in this clock
domain, or connect a FIFO to transfer data into another clock domain of your
choice.  This FIFO should capable of storing at least one burst (size BL/2)
+ start of next burst (size 1).

Synchronous resets are used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/sdram/sdram_ctrl_s3esk.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 69-112



.. only:: latex

   Source file: :pocsrc:`mem/sdram/sdram_ctrl_s3esk.vhdl <mem/sdram/sdram_ctrl_s3esk.vhdl>`
