.. _IP:arith_firstone:

PoC.arith.firstone
##################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_firstone.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_firstone_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_firstone.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_firstone_tb.vhdl>`

Computes from an input word, a word of the same size that has, at most,
one bit set. The output contains a set bit at the position of the rightmost
set bit of the input if and only if such a set bit exists in the input.

A typical use case for this computation would be an arbitration over
requests with a fixed and strictly ordered priority. The terminology of
the interface assumes this use case and provides some useful extras:

* Set tin <= '0' (no input token) to disallow grants altogether.
* Read tout (unused token) to see whether or any grant was issued.
* Read bin to obtain the binary index of the rightmost detected one bit.
  The index starts at zero (0) in the rightmost bit position.

This implementation uses carry chains for wider implementations.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_firstone.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 50-61



.. only:: latex

   Source file: :pocsrc:`arith/arith_firstone.vhdl <arith/arith_firstone.vhdl>`
