.. _IP:arith_shifter_barrel:

PoC.arith.shifter_barrel
########################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_shifter_barrel.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_shifter_barrel_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_shifter_barrel.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_shifter_barrel_tb.vhdl>`

This Barrel-Shifter supports:

* shifting and rotating
* right and left operations
* arithmetic and logic mode (only valid for shift operations)

This is equivalent to the CPU instructions: SLL, SLA, SRL, SRA, RL, RR



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_shifter_barrel.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 45-57



.. only:: latex

   Source file: :pocsrc:`arith/arith_shifter_barrel.vhdl <arith/arith_shifter_barrel.vhdl>`
