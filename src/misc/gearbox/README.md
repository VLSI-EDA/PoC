# Namespace `PoC.misc.gearbox`

The namespace `PoC.misc.gearbox` offers gearbox implementations with different
interfaces.

A gearbox is a bus interface converter, that resizes an input stream of
`INPUT_BITS` to an output stream of `OUTPUT_BITS`, while maintaining a constant
transfer rate. There are two kinds of gearboxes: down-scaling and up-scaling.


### `gearbox_...._cc` Modules

Gearboxes with common clock (`cc`) interface ... TODO

**Gearbox use case:**

 1. TODO

### `gearbox_...._dc` Modules

Gearboxes with full transfer rate preservation use a dependent clock (`dc`)
interface. For example a 32:8 `gearbox_down_dc` with an input frequency of 75 MHz
requires an output frequency of 300 MHz, because the scaling factor is 4. The
clocks MUST be multiples of each other and have a FIXED phase difference.

**Gearbox use case:**

 1. A SATA 3,0 Gbps controller uses an embedded multi-gigabit transceiver (MGT)
    in an FPGA to transmit and receive 300 MBps. The MGT interface is configured
		as a byte interface at 300 MHz. The link layer protocol works on 32 bit
		words. A gearbox_up_dc is used to pack 4 bytes into one 32 bit SATA word at
		a frequency of 75 MHz.

**FIFO use case:**
		
 2. GigabitEthernet (1GbE) uses a byte interface at 125 MHz. After processing MAC,
    IP and UDP packets an overhead of 10 % is expected. Due to the application a
		max link utilisation of 80% is excepted resulting in an effective datarate of
		1 byte at 100 MHz. A `fifo_ic_got` is used to convert between the clock domains.

		
## Entities

 - [`gearbox_down_cc`][gearbox_down_cc] 
 - [`gearbox_up_cc`][gearbox_up_cc] 
 - [`gearbox_down_dc`][gearbox_down_dc] 
 - [`gearbox_up_dc`][gearbox_up_dc] 

 [gearbox_down_cc]:					gearbox_down_cc.vhdl
 [gearbox_up_cc]:						gearbox_up_cc.vhdl
 [gearbox_down_dc]:					gearbox_down_dc.vhdl
 [gearbox_up_dc]:						gearbox_up_dc.vhdl
		