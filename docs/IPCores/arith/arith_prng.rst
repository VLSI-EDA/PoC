.. _IP:arith_prng:

PoC.arith.prng
##############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_prng.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_prng_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_prng.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_prng_tb.vhdl>`

This module implementes a Pseudo-Random Number Generator (PRNG) with
configurable bit count (``BITS``). This module uses an internal list of FPGA
optimized polynomials from 3 to 168 bits. The polynomials have at most 5 tap
positions, so that long shift registers can be inferred instead of single
flip-flops.

The generated number sequence includes the value all-zeros, but not all-ones.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_prng.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 46-57



.. only:: latex

   Source file: :pocsrc:`arith/arith_prng.vhdl <arith/arith_prng.vhdl>`
