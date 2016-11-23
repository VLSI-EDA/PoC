.. _IP:ocram_tdp_sim:

PoC.mem.ocram.tdp_sim
#####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_tdp_sim.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ocram/ocram_tdp_sim_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ocram/ocram_tdp_sim.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ocram/ocram_tdp_sim_tb.vhdl>`

Simulation model for true dual-port memory, with:

* dual clock, clock enable,
* 2 read/write ports.

The interface matches that of the IP core PoC.mem.ocram.tdp.
But the implementation there is restricted to the description supported by
various synthesis compilers. The implementation here also simulates the
correct Mixed-Port Read-During-Write Behavior and handles X propagation.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_tdp_sim.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 51-71



.. only:: latex

   Source file: :pocsrc:`mem/ocram/ocram_tdp_sim.vhdl <mem/ocram/ocram_tdp_sim.vhdl>`
