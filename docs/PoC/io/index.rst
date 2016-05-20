
io
==

These are I/O entities....

# Namespace `PoC.io`


The namespace `PoC.io` offers different general purpose I/O (GPIO) implementations,
as well as low-speed bus protocol controllers.


## Sub-Namespace(s)

 - [`PoC.io.ddrio`][io_ddrio] - Double-Data-Rate (DDR) input/output abstraction layer. 
 - [`PoC.io.iic`][io_iic] - I²C bus controllers
 - [`PoC.io.jtag`][io_jtag] - JTAG implementations
 - [`PoC.io.lcd`][io_lcd] - LC-Display bus controllers
 - [`PoC.io.mdio`][io_mdio] - Management Data I/O (MDIO) controllers for Ethernet PHYs
 - [`PoC.io.ow`][io_ow] - OneWire / iButton bus controllers
 - [`PoC.io.ps2`][io_ps2] - Periphery bus of the Personal System/2 (PS/2)
 - [`PoC.io.uart`][io_uart] - Universal Asynchronous Receiver Transmitter (UART) controllers
 - [`PoC.io.vga`][io_vga] - VGA, DVI, HDMI controllers


## Package(s)

The package [`io][io.pkg] holds all enum, function and component declarations for this namespace.

```VHDL
library PoC;
use     PoC.io.all;
```


## Entities

 -  `io_Debounce`
 -  `io_7SegmentMux_BCD`
 -  `io_7SegmentMux_HEX`
 -  `io_FanControl`
 -  `io_FrequencyCounter`
 -  `io_GlitchFilter`
 -  `io_PulseWidthModulation`
 -  `io_TimingCounter`

 [io.pkg]:			https://github.com/VLSI-EDA/PoC/blob/master/src/io/io.pkg.vhdl

 [io_ddrio]:		src_io_ddrio
 [io_iic]:			src_io_iic
 [io_jtag]:			src_io_jtag
 [io_lcd]:			src_io_lcd
 [io_mdio]:			src_io_mdio
 [io_ow]:			src_io_ow
 [io_ps2]:			src_io_ps2
 [io_uart]:			src_io_uart
 [io_vga]:			src_io_vga



.. toctree::
   
   ddrio/index
   iic/index
   jtag/index
   lcd/index
   mdio/index
   ow/index
   ps2/index
   uart/index
   vga/index
