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

 [io.pkg]:			io.pkg.vhdl

 [io_ddrio]:		ddrio
 [io_iic]:			iic
 [io_jtag]:			jtag
 [io_lcd]:			lcd
 [io_mdio]:			mdio
 [io_ow]:			ow
 [io_ps2]:			ps2
 [io_uart]:			uart
 [io_vga]:			vga
