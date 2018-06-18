.. _IP:fifo_dc_got_sm:

PoC.fifo.dc_got_sm
##################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/fifo/fifo_dc_got_sm.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/fifo/fifo_dc_got_sm_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <fifo/fifo_dc_got_sm.vhdl>`
      * |gh-tb| :poctb:`Testbench <fifo/fifo_dc_got_sm_tb.vhdl>`

Dependent clocks meens, that one clock must be a multiple of the other one.
And your synthesis tool must check for setup- and hold-time violations.

This implementation uses a small register-file for storing data. Your
synthesis tool might infer memory. This memory must
- either support asynchronous reads (as an register-file)
- or a synchronous read with mixed-port read-during-write (write-first).

First-word-fall-through (FWFT) mode is implemented, so data can be read out
as soon as 'valid' goes high. After the data has been captured, then the
signal 'got' must be asserted.

The advantage of the register file is, that data is available at the read
port after the rising edge of the write clock it has been written to.

Because implementing register-files onto a FPGA might require a lot of LUT
logic, use this implementation only for small FIFOs.

Another disadvantage is, that the signals 'full' and
'valid' are combinatorial and include an adress comparator in their path.

The specified depth (MIN_DEPTH) is rounded up to the next suitable value.

Synchronous reset is used. Both resets must overlap.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/fifo/fifo_dc_got_sm.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 62-85



.. only:: latex

   Source file: :pocsrc:`fifo/fifo_dc_got_sm.vhdl <fifo/fifo_dc_got_sm.vhdl>`
