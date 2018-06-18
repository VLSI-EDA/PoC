.. _IP:ocram_sdp_wf:

PoC.mem.ocram.sdp_wf
####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sdp_wf.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ocram/ocram_sdp_wf_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ocram/ocram_sdp_wf.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ocram/ocram_sdp_wf_tb.vhdl>`

Inferring / instantiating simple dual-port memory, with:

* single clock, clock enable,
* 1 read port plus 1 write port.

Command truth table:

== == ===============================
ce we Command
== == ===============================
0   X   No operation
1   0   Read only from memory
1   1   Read from and Write to memory
== == ===============================

Both reading and writing are synchronous to the rising-edge of the clock.
Thus, when reading, the memory data will be outputted after the
clock edge, i.e, in the following clock cycle.

Mixed-Port Read-During-Write
  When reading at the write address, the read value will be the new data,
  aka. "write-first behavior". Of course, the read is still synchronous,
  i.e, the latency is still one clock cyle.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_sdp_wf.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 57-72



.. only:: latex

   Source file: :pocsrc:`mem/ocram/ocram_sdp_wf.vhdl <mem/ocram/ocram_sdp_wf.vhdl>`
