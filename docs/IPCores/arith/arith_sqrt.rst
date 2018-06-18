.. _IP:arith_sqrt:

PoC.arith.sqrt
##############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_sqrt.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_sqrt_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_sqrt.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_sqrt_tb.vhdl>`

Iterative Square Root Extractor.

Its computation requires (N+1)/2 steps for an argument bit width of N.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_sqrt.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 38-55



.. only:: latex

   Source file: :pocsrc:`arith/arith_sqrt.vhdl <arith/arith_sqrt.vhdl>`
