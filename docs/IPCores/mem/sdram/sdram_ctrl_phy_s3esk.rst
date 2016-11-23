.. _IP:sdram_ctrl_phy_s3esk:

PoC.mem.sdram.ctrl_phy_s3esk
############################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/sdram/sdram_ctrl_phy_s3esk.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/sdram/sdram_ctrl_phy_s3esk_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/sdram/sdram_ctrl_phy_s3esk.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/sdram/sdram_ctrl_phy_s3esk_tb.vhdl>`

Physical layer used by module :ref:`sdram_ctrl_s3esk <IP:sdram_ctrl_s3esk>`.

Instantiates input and output buffer components and adjusts the timing for
the Spartan-3E Starter Kit Board.

Clock and Reset Signals
***********************

+-----------+-----------------------------------------------------------+
| Port      | Description                                               |
+===========+===========================================================+
|clk        | Base clock for command and write data path.               |
+-----------+-----------------------------------------------------------+
|clk_n      | ``clk`` phase shifted by 180 degrees.                     |
+-----------+-----------------------------------------------------------+
|clk90      | ``clk`` phase shifted by  90 degrees.                     |
+-----------+-----------------------------------------------------------+
|clk90_n    | ``clk`` phase shifted by 270 degrees.                     |
+-----------+-----------------------------------------------------------+
|clk_fb     | Driven by external feedback (sd_ck_fb) of DDR-SDRAM clock |
|(on PCB)   | (sd_ck_p). Actually unused, just referenced below.        |
+-----------+-----------------------------------------------------------+
|clk_fb90   | ``clk_fb`` phase shifted by 90 degrees.                   |
+-----------+-----------------------------------------------------------+
|clk_fb90_n | ``clk_fb`` phase shifted by 270 degrees.                  |
+-----------+-----------------------------------------------------------+
|rst        | Reset for ``clk``.                                        |
+-----------+-----------------------------------------------------------+
|rst180     | Reset for ``clk_n``                                       |
+-----------+-----------------------------------------------------------+
|rst90      | Reset for ``clk90``.                                      |
+-----------+-----------------------------------------------------------+
|rst270     | Reset for ``clk270``.                                     |
+-----------+-----------------------------------------------------------+
|rst_fb90   | Reset for ``clk_fb90``.                                   |
+-----------+-----------------------------------------------------------+
|rst_fb90_n | Reset for ``clk_fb90_n``.                                 |
+-----------+-----------------------------------------------------------+


Operation
*********

Command signals and write data are sampled with the rising edge of ``clk``.

Read data is aligned with ``clk_fb90_n``. Either process data in this clock
domain, or connect a FIFO to transfer data into another clock domain of your
choice.  This FIFO should capable of storing at least one burst (size BL/2)
+ start of next burst (size 1).

Write and read enable (``wren_nxt``, ``rden_nxt``) must be hold for:

* 1 clock cycle  if BL = 2,
* 2 clock cycles if BL = 4, or
* 4 clock cycles if BL = 8.

They must be first asserted with the read and write command. Proper delay is
included in this unit.

The first word to write must be asserted with the write command. Proper
delay is included in this unit.

The SDRAM clock is regenerated in this module. The following timing is
chosen for minimum latency (should work up to 100 MHz):

* ``rising_edge(clk90)``   triggers ``rising_edge(sd_ck_p)``,
* ``rising_edge(clk90_n)`` triggers ``falling_edge(sd_ck_p)``.

XST options: Disable equivalent register removal.

Synchronous resets are used. Reset must be hold for at least two cycles.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/sdram/sdram_ctrl_phy_s3esk.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 107-151



.. only:: latex

   Source file: :pocsrc:`mem/sdram/sdram_ctrl_phy_s3esk.vhdl <mem/sdram/sdram_ctrl_phy_s3esk.vhdl>`
