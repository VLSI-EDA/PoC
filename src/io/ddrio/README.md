# Namespace `PoC.io.ddrio`

The namespace `PoC.io.ddrio` offers components for dual-data-rate (DDR) input
and output of data. It uses the DDR flip flops in the FPGA
I/O buffers, if available. PoC has two platform specific
implementations for Altera and Xilinx, which are chosen, if the
appropriate `MY_DEVICE` is configured in [`my_config.vhdl`][my_config].
 

## Package(s)

The package [`PoC.ddrio`][ddrio.pkg] holds all component declarations for this namespace.


## Entities

#### Dual-Data-Rate Input

The module [`ddrio_in`][ddrio_in] captures the input data at the pad
with both edges of the clock. The data captured with the falling edge
is again synchronized to the rising edge, so that both data parts are
provided for the internal logic with the rising edge of the clock.

It's possible to configure the width of the data bus as well as the
initialization state provided for the internal logic. The vendor specific
implementations are named [`ddrio_in_altera`][ddrio_in_altera] and
[`ddrio_in_xilinx`][ddrio_in_xilinx] respectively.

See the ASCII art inside the [VHDL description][ddrio_in] for more
details on how data to is sampled at the pad.


#### Dual-Data-Rate Output

The module [`ddrio_out`][ddrio_out] brings out the ouput data at the pad
with both edges of the clock. The data is sampled from the internal logic
with the rising edge only.

It's possible to configure the width of the data bus as well as the
initialization state of the value present at the pad. The output
driver can be disabled by a synchronous control signal. This control
signal can be removed by a parameter to save some logic. The vendor specific
implementations are named [`ddrio_out_altera`][ddrio_out_altera] and
[`ddrio_out_xilinx`][ddrio_out_xilinx] respectively.

See the ASCII art inside the [VHDL description][ddrio_out] for more
details on how data to is driven at the pad.


#### Dual-Data-Rate Input and Output

The module [`ddrio_inout`][ddrio_inout] is combination of the DDR
input and DDR output functionality described above. Two different
clocks are available for the input side and the output side.

It's possible to configure the width of the data bus, but not the 
initialization state due to a limitation of the Altera specific
implementation. The vendor specific implementations are named
[`ddrio_inout_altera`][ddrio_inout_altera] and 
[`ddrio_inout_xilinx`][ddrio_inout_xilinx] respectively.

See the ASCII art inside the [VHDL description][ddrio_inout] for more
details on how data to is sampled and driven at the pad.


 [my_config]:						../../common/my_config.vhdl.template
 [ddrio.pkg]:						ddrio.pkg.vhdl
 [ddrio_in]:						ddrio_in.vhdl
 [ddrio_in_altera]:			ddrio_in_altera.vhdl
 [ddrio_in_xilinx]:			ddrio_in_xilinx.vhdl
 [ddrio_inout]:					ddrio_inout.vhdl
 [ddrio_inout_altera]:	ddrio_inout_altera.vhdl
 [ddrio_inout_xilinx]:	ddrio_inout_xilinx.vhdl
 [ddrio_out]:						ddrio_out.vhdl
 [ddrio_out_altera]:		ddrio_out_altera.vhdl
 [ddrio_out_xilinx]:		ddrio_out_xilinx.vhdl
