.. _IP:vga_phy_ch7301c:

PoC.io.vga.phy_ch7301c
######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/vga/vga_phy_ch7301c.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/vga/vga_phy_ch7301c_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/vga/vga_phy_ch7301c.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/vga/vga_phy_ch7301c_tb.vhdl>`

The clock frequency must be the same as used for the timing module,
e.g., 25 MHZ for VGA 640x480. A phase-shifted clock must be provided:
- clk0	:		0 degrees
- clk90	:	90 degrees

pixel_data(23 downto 16) : red
pixel_data(15 downto	8) : green
pixel_data( 7 downto	0) : blue

The ``reset_b``-pin must be driven by other logic (such as the reset button).

The IIC_interface is not part of this modules, as an IIC-master controls
several slaves. The following registers must be set, see
tests/ml505/vga_test_ml505.vhdl for an example.

+----------+--------------------------------------+---------------------------------+
| Register | Value                                |  Description                    |
+==========+======================================+=================================+
|0x49 PM   | 0xC0                                 | Enable DVI, RGB bypass off      |
|          | 0xD0                                 | Enable DVI, RGB bypass on       |
+----------+--------------------------------------+---------------------------------+
|0x33 TPCP | 0x08 if clk_freq <= 65 MHz else 0x06 |                                 |
+----------+--------------------------------------+---------------------------------+
|0x34 TPD  | 0x16 if clk_freq <= 65 MHz else 0x26 |                                 |
+----------+--------------------------------------+---------------------------------+
|0x36 TPF  | 0x60 if clk_freq <= 65 MHz else 0xA0 |                                 |
+----------+--------------------------------------+---------------------------------+
|0x1F IDF  | 0x80                                 | when using SMT (VS0, HS0)       |
|          | 0x90                                 | when using CVT (VS1, HS0)       |
+----------+--------------------------------------+---------------------------------+
|0x21 DC   | 0x09                                 | Enable DAC if RGB bypass is on  |
+----------+--------------------------------------+---------------------------------+



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/vga/vga_phy_ch7301c.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 70-83



.. only:: latex

   Source file: :pocsrc:`io/vga/vga_phy_ch7301c.vhdl <io/vga/vga_phy_ch7301c.vhdl>`
