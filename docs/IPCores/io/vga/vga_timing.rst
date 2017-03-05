.. _IP:vga_timing:

PoC.io.vga.timing
#################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/io/vga/vga_timing.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/io/vga/vga_timing_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <io/vga/vga_timing.vhdl>`
      * |gh-tb| :poctb:`Testbench <io/vga/vga_timing_tb.vhdl>`

Configuration:
--------------
MODE = 0: VGA mode with  640x480  pixels, 60 Hz, frequency(clk) ~  25	MHz
MODE = 1: HD  720p with 1280x720  pixels, 60 Hz, frequency(clk) =  74,5 MHz
MODE = 2: HD 1080p with 1920x1080 pixels, 60 Hz, frequency(clk) = 138,5 MHz

MODE = 2 uses reduced blanking => only suitable for LCDs.

For MODE = 0, CVT can be configured:
- CVT = false: Use Safe Mode Timing (SMT).
	 The legacy fall-back mode supported by CRTs as well as LCDs.
	 HSync: low-active. VSync: low-active.
	 frequency(clk) = 25.175 MHz. (25 MHz works => 31 kHz / 59 Hz)
- CVT = true: The "new" Coordinated Video Timing (since 2003).
	 The CVT supports some new features, such as reduced blanking (for LCDs) or
	 aspect ratio encoding. See the web for more details.
	 Standard CRT-based timing (CVT-GTF) has been implemented for best
	 compatibility:
	 HSync: low-active. VSync: high-active.
	 frequency(clk) = 23.75 MHz. (25 MHz works => 31 kHz / 62 Hz)

Usage:
------
The frequency of ``clk`` must be equal to the pixel clock frequency of the
selected video mode, see also above.

When using analog output, the VGA color signals must be blanked, during
horizontal and vertical beam return. This could be achieved by
combinatorial "anding" the color value with "beam_on" (part of "phy_ctrl")
inside the PHY.

When using digital output (DVI), then "beam_on" is equal to "DE"
(Data Enable) of the DVI transmitter.

xvalid and yvalid show if xpos respectivly ypos are in a valid range.
beam_on is '1' iff both xvalid and yvalid = '1'.

xpos and ypos also show the pixel location during blanking.
This might be useful in some applications. But be careful, that the ranges
differ between SMT and CVT.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/vga/vga_timing.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 80-96



.. only:: latex

   Source file: :pocsrc:`io/vga/vga_timing.vhdl <io/vga/vga_timing.vhdl>`
