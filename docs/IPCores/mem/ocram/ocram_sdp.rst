.. _IP:ocram_sdp:

PoC.mem.ocram.sdp
#################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sdp.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ocram/ocram_sdp_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ocram/ocram_sdp.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ocram/ocram_sdp_tb.vhdl>`

Inferring / instantiating simple dual-port memory, with:

* dual clock, clock enable,
* 1 read port plus 1 write port.

Both reading and writing are synchronous to the rising-edge of the clock.
Thus, when reading, the memory data will be outputted after the
clock edge, i.e, in the following clock cycle.

The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:

Mixed-Port Read-During-Write
  When reading at the write address, the read value will be unknown which is
  aka. "don't care behavior". This applies to all reads (at the same
  address) which are issued during the write-cycle time, which starts at the
  rising-edge of the write clock and (in the worst case) extends until the
  next rising-edge of the write clock.

For simulation, always our dedicated simulation model :ref:`IP:ocram_tdp_sim`
is used.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_sdp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 65-82



.. only:: latex

   Source file: :pocsrc:`mem/ocram/ocram_sdp.vhdl <mem/ocram/ocram_sdp.vhdl>`
