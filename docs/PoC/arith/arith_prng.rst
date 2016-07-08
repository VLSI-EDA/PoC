
arith_prng
##########

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

Source file: `arith/arith_prng.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_prng.vhdl>`_


 
