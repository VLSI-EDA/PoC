.. _IP:ocram_esdp:

PoC.mem.ocram.esdp
##################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_esdp.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ocram/ocram_esdp_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ocram/ocram_esdp.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ocram/ocram_esdp_tb.vhdl>`

Inferring / instantiating enhanced simple dual-port memory, with:

* dual clock, clock enable,
* 1 read/write port (1st port) plus 1 read port (2nd port).

.. deprecated:: 1.1

   **Please use** :ref:`IP:ocram_tdp` **for new designs.
   This component has been provided because older FPGA compilers where not
   able to infer true dual-port memory from an RTL description.**

Command truth table for port 1:

=== === ================
ce1 we1 Command
=== === ================
0   X   No operation
1   0   Read from memory
1   1   Write to memory
=== === ================

Command truth table for port 2:

=== ================
ce2 Command
=== ================
0   No operation
1   Read from memory
=== ================

Both reading and writing are synchronous to the rising-edge of the clock.
Thus, when reading, the memory data will be outputted after the
clock edge, i.e, in the following clock cycle.

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

Same-Port Read-During-Write
  When writing data through port 1, the read output of the same port
  (``q1``) will output the new data (``d1``, in the following clock cycle)
  which is aka. "write-first behavior".

Mixed-Port Read-During-Write
  When reading at the write address, the read value will be unknown which is
  aka. "don't care behavior". This applies to all reads (at the same
  address) which are issued during the write-cycle time, which starts at the
  rising-edge of the write clock (``clk1``) and (in the worst case) extends
  until the next rising-edge of the write clock.

For simulation, always our dedicated simulation model :ref:`IP:ocram_tdp_sim`
is used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_esdp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 97-115



.. only:: latex

   Source file: :pocsrc:`mem/ocram/ocram_esdp.vhdl <mem/ocram/ocram_esdp.vhdl>`
