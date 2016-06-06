
ddrio_out
#########

Instantiates chip-specific DDR output registers.

Both data "DataOut_high/low" as well as "OutputEnable" are sampled with
the rising_edge(Clock) from the on-chip logic. "DataOut_high" is brought
out with this rising edge. "DataOut_low" is brought out with the falling
edge.

"OutputEnable" (Tri-State) is high-active. It is automatically inverted if
necessary. If an output enable is not required, you may save some logic by
setting NO_OUTPUT_ENABLE = true.

If NO_OUTPUT_ENABLE = false then output is disabled after power-up.
If NO_OUTPUT_ENABLE = true then output after power-up equals INIT_VALUE.

"Pad" must be connected to a PAD because FPGAs only have these registers in
IOBs.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/ddrio/ddrio_out.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 57-71


	 