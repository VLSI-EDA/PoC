.. _IP:vga_phy:

PoC.io.vga.phy
##############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/vga/vga_phy.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/vga/vga_phy_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/vga/vga_phy.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/vga/vga_phy_tb.vhdl>`

	The clock frequency must be the same as used for the timing module.

	The number of color-bits per pixel can be configured with the generic
	"COLOR_BITS". The format of the pixel data is defined the picture generator
	in use.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/vga/vga_phy.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 43-55



.. only:: latex

   Source file: :pocsrc:`io/vga/vga_phy.vhdl <io/vga/vga_phy.vhdl>`
