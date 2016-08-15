
ddrio_in
########

Instantiates chip-specific :abbr:`DDR (Double Data Rate)` input registers.

Both data ``DataIn_high/low`` are synchronously outputted to the on-chip logic
with the rising edge of ``Clock``. ``DataIn_high`` is the value at the ``Pad``
sampled with the same rising edge. ``DataIn_low`` is the value sampled with
the falling edge directly before this rising edge. Thus sampling starts with
the falling edge of the clock as depicted in the following waveform.

.. code-block:: none
   
                __      ____      ____      __
   Clock          |____|    |____|    |____|
   Pad          < 0 >< 1 >< 2 >< 3 >< 4 >< 5 >
   DataIn_low      ... >< 0      >< 2      ><
   DataIn_high     ... >< 1      >< 3      ><
   
   < i > is the value of the i-th data bit on the line.

After power-up, the output ports ``DataIn_high`` and ``DataIn_low`` both equal
INIT_VALUE.

``Pad`` must be connected to a PAD because FPGAs only have these registers in
IOBs.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/io/ddrio/ddrio_in.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 64-76

Source file: `io/ddrio/ddrio_in.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/io/ddrio/ddrio_in.vhdl>`_


	 