.. _IP:fifo_ic_got:

PoC.fifo.ic_got
###############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/fifo/fifo_ic_got.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/fifo/fifo_ic_got_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <fifo/fifo_ic_got.vhdl>`
      * |gh-tb| :poctb:`Testbench <fifo/fifo_ic_got_tb.vhdl>`

Independent clocks meens that read and write clock are unrelated.

This implementation uses dedicated block RAM for storing data.

First-word-fall-through (FWFT) mode is implemented, so data can be read out
as soon as ``valid`` goes high. After the data has been captured, then the
signal ``got`` must be asserted.

Synchronous reset is used. Both resets may overlap.

``DATA_REG`` (=true) is a hint, that distributed memory or registers should be
used as data storage. The actual memory type depends on the device
architecture. See implementation for details.

``*STATE_*_BITS`` defines the granularity of the fill state indicator
``*state_*``. ``fstate_rd`` is associated with the read clock domain and outputs
the guaranteed number of words available in the FIFO. ``estate_wr`` is
associated with the write clock domain and outputs the number of words that
is guaranteed to be accepted by the FIFO without a capacity overflow. Note
that both these indicators cannot replace the ``full`` or ``valid`` outputs as
they may be implemented as giving pessimistic bounds that are minimally off
the true fill state.

If a fill state is not of interest, set *STATE_*_BITS = 0.

``fstate_rd`` and ``estate_wr`` are combinatorial outputs and include an address
comparator (subtractor) in their path.

Examples:
- FSTATE_RD_BITS = 1: fstate_rd == 0 => 0/2 full
                      fstate_rd == 1 => 1/2 full (half full)

- FSTATE_RD_BITS = 2: fstate_rd == 0 => 0/4 full
                      fstate_rd == 1 => 1/4 full
                      fstate_rd == 2 => 2/4 full
                      fstate_rd == 3 => 3/4 full



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/fifo/fifo_ic_got.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 77-103



.. only:: latex

   Source file: :pocsrc:`fifo/fifo_ic_got.vhdl <fifo/fifo_ic_got.vhdl>`
