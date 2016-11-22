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


.. _IP:ocram_sdp_wf:

ocram_sdp_wf
############

Inferring / instantiating simple dual-port memory, with:

* single clock, clock enable,
* 1 read port plus 1 write port.

Mixed-Port Read-During-Write
  When reading at the write address, the read value will be the new data,
  aka. "write-first behavior". Of course, the read is still synchronous,
  i.e, the latency is still one clock cyle.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_sdp_wf.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 43-58



.. only:: latex

   Source file: :pocsrc:`mem/ocram/ocram_sdp_wf.vhdl <mem/ocram/ocram_sdp_wf.vhdl>`
