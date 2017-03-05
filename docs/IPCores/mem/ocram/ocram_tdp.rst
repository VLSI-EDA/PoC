.. _IP:ocram_tdp:

PoC.mem.ocram.tdp
#################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_tdp.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ocram/ocram_tdp_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ocram/ocram_tdp.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ocram/ocram_tdp_tb.vhdl>`

Inferring / instantiating true dual-port memory, with:

* dual clock, clock enable,
* 2 read/write ports.

Command truth table for port 1, same applies to port 2:

=== === ================
ce1 we1 Command
=== === ================
0   X   No operation
1   0   Read from memory
1   1   Write to memory
=== === ================

Both reading and writing are synchronous to the rising-edge of the clock.
Thus, when reading, the memory data will be outputted after the
clock edge, i.e, in the following clock cycle.

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

Same-Port Read-During-Write
  When writing data through port 1, the read output of the same port
  (``q1``) will output the new data (``d1``, in the following clock cycle)
  which is aka. "write-first behavior".

  Same applies to port 2.

Mixed-Port Read-During-Write
  When reading at the write address, the read value will be unknown which is
  aka. "don't care behavior". This applies to all reads (at the same
  address) which are issued during the write-cycle time, which starts at the
  rising-edge of the write clock and (in the worst case) extends
  until the next rising-edge of that write clock.

For simulation, always our dedicated simulation model :ref:`IP:ocram_tdp_sim`
is used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_tdp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 82-102



.. only:: latex

   Source file: :pocsrc:`mem/ocram/ocram_tdp.vhdl <mem/ocram/ocram_tdp.vhdl>`
