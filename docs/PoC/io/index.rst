
io
==

These are I/O entities....

# Namespace ``PoC.io``


The namespace ``PoC.io`` offers different general purpose I/O (GPIO) implementations,
as well as low-speed bus protocol controllers.

.. ## Sub-Namespace(s)
   
   - :doc:`PoC.io.ddrio <io_ddrio>` - Double-Data-Rate (DDR) input/output abstraction layer. 
   - :doc:`PoC.io.iic <io_iic>` - I²C bus controllers
   - :doc:`PoC.io.jtag <io_jtag>` - JTAG implementations
   - :doc:`PoC.io.lcd <io_lcd>` - LC-Display bus controllers
   - :doc:`PoC.io.mdio <io_mdio>` - Management Data I/O (MDIO) controllers for Ethernet PHYs
   - :doc:`PoC.io.ow <io_ow>` - OneWire / iButton bus controllers
   - :doc:`PoC.io.ps2 <io_ps2>` - Periphery bus of the Personal System/2 (PS/2)
   - :doc:`PoC.io.uart <io_uart>` - Universal Asynchronous Receiver Transmitter (UART) controllers
   - :doc:`PoC.io.vga <io_vga>` - VGA, DVI, HDMI controllers


.. ## Package(s)

The package `io>`[io.pkg>` holds all enum, function and component declarations for this namespace.


.. ## Entities
   
   -  ``io_Debounce``
   -  ``io_7SegmentMux_BCD``
   -  ``io_7SegmentMux_HEX``
   -  ``io_FanControl``
   -  ``io_FrequencyCounter``
   -  ``io_GlitchFilter``
   -  ``io_PulseWidthModulation``
   -  ``io_TimingCounter``

.. 
   [io.pkg>`:			https://github.com/VLSI-EDA/PoC/blob/master/src/io/io.pkg.vhdl

.. rubric:: Sub-Namespaces

.. toctree::
   
   ddrio/index
   iic/index
   jtag/index
   lcd/index
   mdio/index
   ow/index
   pio/index
   pmod/index
   ps2/index
   uart/index
   vga/index

.. rubric:: Sub-Namespaces

.. toctree::
   
   io_7SegmentMux_BCD
   io_7SegmentMux_HEX
   io_Debounce
   io_FanControl
   io_FrequencyCounter
   io_GlitchFilter
   io_KeyPadScanner
   io_PulseWidthModulation
   io_TimingCounter
