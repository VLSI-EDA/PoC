.. _IP:arith_muls_wide:

PoC.arith.muls_wide
###################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_muls_wide.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_muls_wide_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_muls_wide.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_muls_wide_tb.vhdl>`

Signed wide multiplication spanning multiple DSP or MULT blocks.
Small partial products are calculated through LUTs.
For detailed documentation see below.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_muls_wide.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 38-49



.. only:: latex

   Source file: :pocsrc:`arith/arith_muls_wide.vhdl <arith/arith_muls_wide.vhdl>`
