.. _IP:sdram_ctrl_phy_de0:

PoC.mem.sdram.ctrl_phy_de0
##########################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/sdram/sdram_ctrl_phy_de0.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/sdram/sdram_ctrl_phy_de0_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/sdram/sdram_ctrl_phy_de0.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/sdram/sdram_ctrl_phy_de0_tb.vhdl>`

Physical layer used by module :ref:`sdram_ctrl_de0 <IP:sdram_ctrl_de0>`.

Instantiates input and output buffer components and adjusts the timing for
the Altera DE0 board.

Clock and Reset Signals
***********************

+-----------+-----------------------------------------------------------+
| Port      | Description                                               |
+===========+===========================================================+
|clk        | Base clock for command and write data path.               |
+-----------+-----------------------------------------------------------+
|rst        | Reset for ``clk``.                                        |
+-----------+-----------------------------------------------------------+

Command signals and write data are sampled with ``clk``.
Read data is also aligned with ``clk``.

Write and read enable (wren_nxt, rden_nxt) must be hold for:

* 1 clock cycle  if BL = 1,
* 2 clock cycles if BL = 2, or
* 4 clock cycles if BL = 4, or
* 8 clock cycles if BL = 8.

They must be first asserted with the read and write command. Proper delay is
included in this unit.

The first word to write must be asserted with the write command. Proper
delay is included in this unit.

Synchronous resets are used. Reset must be hold for at least two cycles.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/sdram/sdram_ctrl_phy_de0.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 89-122



.. only:: latex

   Source file: :pocsrc:`mem/sdram/sdram_ctrl_phy_de0.vhdl <mem/sdram/sdram_ctrl_phy_de0.vhdl>`
