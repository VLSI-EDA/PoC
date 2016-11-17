.. _NS:io:

PoC.io
======

The namespace ``PoC.io`` offers different general purpose I/O (GPIO) implementations,
as well as low-speed bus protocol controllers.

**Sub-namespaces**

 * :doc:`PoC.io.ddrio <ddrio/index>` - Double-Data-Rate (DDR) input/output abstraction layer.
 * :doc:`PoC.io.iic <iic/index>` - I²C bus controllers
 * :doc:`PoC.io.jtag <jtag/index>` - JTAG implementations
 * :doc:`PoC.io.lcd <lcd/index>` - LC-Display bus controllers
 * :doc:`PoC.io.mdio <mdio/index>` - Management Data I/O (MDIO) controllers for Ethernet PHYs
 * :doc:`PoC.io.ow <ow/index>` - OneWire / iButton bus controllers
 * :doc:`PoC.io.ps2 <ps2/index>` - Periphery bus of the Personal System/2 (PS/2)
 * :doc:`PoC.io.uart <uart/index>` - Universal Asynchronous Receiver Transmitter (UART) controllers
 * :doc:`PoC.io.vga <vga/index>` - VGA, DVI, HDMI controllers

**Package**

The package :doc:`PoC.io <io.pkg>` holds all enum, function and component declarations for this namespace.

**Entities**

 * :doc:`PoC.io.Debounce <io_Debounce>`
 * :doc:`PoC.io.7SegmentMux_BCD <io_7SegmentMux_BCD>`
 * :doc:`PoC.io.7SegmentMux_HEX <io_7SegmentMux_HEX>`
 * :doc:`PoC.io.FanControl <io_FanControl>`
 * :doc:`PoC.io.FrequencyCounter <io_FrequencyCounter>`
 * :doc:`PoC.io.GlitchFilter <io_GlitchFilter>`
 * :doc:`PoC.io.PulseWidthModulation <io_PulseWidthModulation>`
 * :doc:`PoC.io.TimingCounter <io_TimingCounter>`


.. toctree::
   :hidden:

   ddrio <ddrio/index>
   iic <iic/index>
   jtag <jtag/index>
   lcd <lcd/index>
   mdio <mdio/index>
   ow <ow/index>
   pio <pio/index>
   pmod <pmod/index>
   ps2 <ps2/index>
   uart <uart/index>
   vga <vga/index>

.. toctree::
   :hidden:

   Package <io.pkg>

.. toctree::
   :hidden:

   io_7SegmentMux_BCD
   io_7SegmentMux_HEX
   io_Debounce
   io_FanControl
   io_FrequencyCounter
   io_GlitchFilter
   io_KeyPadScanner
   io_PulseWidthModulation
   io_TimingCounter
