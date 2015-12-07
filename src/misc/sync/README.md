# Namespace `PoC.misc.sync`

The namespace PoC.misc.sync offers different clock-domain-crossing (CDC) synchronizer
circuits. All synchronizers are based on the basic 2 flip-flop synchonizer called
[`sync_Bits`][sync_Bits]. PoC has two platform specific implementations for Altera
and Xilinx, which are choosen, if the appropriate `MY_DEVICE` is configured in
[`my_config.vhdl`][my_config].
 

## Package(s)

The package [`sync`][sync.pkg] holds all component declarations for this namespace.

```VHDL
library PoC;
use     PoC.sync.all;
```


## Entities

#### Basic 2 Flip-Flop Synchronizer

The basic 2 flip-flop synchronizer is called [`sync_Bits`][sync_Bits]. It's possible
to configure the bit count of indivital bits. If a vector shall be synchronized,
use one of the special synchronizers like `sync_Vector`. The vendor specific
implementations are named [`sync_Bits_Altera`][sync_Bits_Altera] and
[`sync_Bits_Xilinx`][sync_Bits_Xilinx] respectivily.

A second variant of the 2-FF synchronizer is called [`sync_Reset`][sync_Reset].
It's for `Reset`-signals, implementing asynchronous assertion and synchronous
deassertion. The vendor specific implementations are named [`sync_Reset_Altera`][sync_Reset_Altera]
and [`sync_Reset_Xilinx`][sync_Reset_Xilinx] respectivily.

#### Special Synchronizers

Based on the 2-FF synchronizer, several "high-level" synchronizers are build.

 -  [`sync_Strobe`][sync_Strobe] synchronizes `Strobe`-signals across clock-domain-boundaries. A busy
    signal indicates the synchronization status and can be used as a internal
    gate-signal to disallow new incoming strobes. A `Strobe`-signal is only for
    one clock period active.
 -  [`sync_Command`][sync_Command] like sync_Strobe, it synchronizes a one clock period active
    signal across the clock-domain-boundary, but the input has multiple bits.
    After the multi bit strobe (Command) was transfered, the output goes to its
    idle value.
 -  [`sync_Vector`][sync_Vector] synchronizes a complete vector across the clock-domain-boundary.
    A changed detection on the input vector causes a register to latch the current
    state. The changed event is transfered to the new clock-domain and triggers a
    register to store the latched content, but in the new clock domain. 

See [`PoC.fifo.ic_got`][fifo] for a cross-clock capable FIFO.

 [my_config]:			../../common/my_config.vhdl.template
 [sync.pkg]:			sync.pkg.vhdl
 [sync_Bits]:			sync_Bits.vhdl
 [sync_Bits_Altera]:	sync_Bits_Altera.vhdl
 [sync_Bits_Xilinx]:	sync_Bits_Xilinx.vhdl
 [sync_Reset]:			sync_Reset.vhdl
 [sync_Reset_Altera]:	sync_Reset_Altera.vhdl
 [sync_Reset_Xilinx]:	sync_Reset_Xilinx.vhdl
 [sync_Strobe]:			sync_Strobe.vhdl
 [sync_Command]:		sync_Command.vhdl
 [sync_Vector]:			sync_Vector.vhdl

 [fifo]:				../../fifo
