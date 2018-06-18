.. _IP:fifo_cc_got_tempput:

PoC.fifo.cc_got_tempput
#######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/fifo/fifo_cc_got_tempput.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/fifo/fifo_cc_got_tempput_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <fifo/fifo_cc_got_tempput.vhdl>`
      * |gh-tb| :poctb:`Testbench <fifo/fifo_cc_got_tempput_tb.vhdl>`

The specified depth (``MIN_DEPTH``) is rounded up to the next suitable value.

As uncommitted writes populate FIFO space that is not yet available for
reading, an instance of this FIFO can, indeed, report ``full`` and ``not vld``
at the same time. While a ``commit`` would eventually make data available for
reading (``vld``), a ``rollback`` would free the space for subsequent writing
(``not ful``).

``commit`` and ``rollback`` are inclusive and apply to all writes (``put``) since
the previous 'commit' or 'rollback' up to and including a potentially
simultaneous write.

The FIFO state upon a simultaneous assertion of ``commit`` and ``rollback`` is
*undefined*.

``*STATE_*_BITS`` defines the granularity of the fill state indicator
``*state_*``. ``fstate_rd`` is associated with the read clock domain and outputs
the guaranteed number of words available in the FIFO. ``estate_wr`` is
associated with the write clock domain and outputs the number of words that
is guaranteed to be accepted by the FIFO without a capacity overflow. Note
that both these indicators cannot replace the ``full`` or ``valid`` outputs as
they may be implemented as giving pessimistic bounds that are minimally off
the true fill state.

If a fill state is not of interest, set ``*STATE_*_BITS = 0``.

``fstate_rd`` and ``estate_wr`` are combinatorial outputs and include an address
comparator (subtractor) in their path.

**Examples:**

* FSTATE_RD_BITS = 1:

  * fstate_rd == 0 => 0/2 full
  * fstate_rd == 1 => 1/2 full (half full)

* FSTATE_RD_BITS = 2:

  * fstate_rd == 0 => 0/4 full
  * fstate_rd == 1 => 1/4 full
  * fstate_rd == 2 => 2/4 full
  * fstate_rd == 3 => 3/4 full



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/fifo/fifo_cc_got_tempput.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 85-114



.. only:: latex

   Source file: :pocsrc:`fifo/fifo_cc_got_tempput.vhdl <fifo/fifo_cc_got_tempput.vhdl>`
