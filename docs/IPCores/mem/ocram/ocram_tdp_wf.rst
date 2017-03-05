.. _IP:ocram_tdp_wf:

PoC.mem.ocram.tdp_wf
####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_tdp_wf.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ocram/ocram_tdp_wf_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ocram/ocram_tdp_wf.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ocram/ocram_tdp_wf_tb.vhdl>`

Inferring / instantiating true dual-port memory, with:

* single clock, clock enable,
* 2 read/write ports.

Command truth table:

== === === =====================================================
ce we1 we2 Command
== === === =====================================================
0   X   X  No operation
1   0   0  Read only from memory
1   0   1  Read from memory on port 1, write to memory on port 2
1   1   0  Write to memory on port 1, read from memory on port 2
1   1   1  Write to memory on both ports
== === === =====================================================

Both reads and writes are synchronous to the clock.

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

Same-Port Read-During-Write
  When writing data through port 1, the read output of the same port
  (``q1``) will output the new data (``d1``, in the following clock cycle)
  which is aka. "write-first behavior".

  Same applies to port 2.

Mixed-Port Read-During-Write
  When reading at the write address, the read value will be the new data,
  aka. "write-first behavior". Of course, the read is still synchronous,
  i.e, the latency is still one clock cyle.

If a write is issued on both ports to the same address, then the output of
this unit and the content of the addressed memory cell are undefined.

For simulation, always our dedicated simulation model :ref:`IP:ocram_tdp_sim`
is used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_tdp_wf.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 83-101



.. only:: latex

   Source file: :pocsrc:`mem/ocram/ocram_tdp_wf.vhdl <mem/ocram/ocram_tdp_wf.vhdl>`
