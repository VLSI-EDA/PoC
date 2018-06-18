.. _IP:arith_carrychain_inc:

PoC.arith.carrychain_inc
########################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_carrychain_inc.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_carrychain_inc_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_carrychain_inc.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_carrychain_inc_tb.vhdl>`

This is a generic carry-chain abstraction for increment by one operations.

Y <= X + (0...0) & Cin



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_carrychain_inc.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 43-52



.. only:: latex

   Source file: :pocsrc:`arith/arith_carrychain_inc.vhdl <arith/arith_carrychain_inc.vhdl>`
