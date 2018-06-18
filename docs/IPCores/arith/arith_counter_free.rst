.. _IP:arith_counter_free:

PoC.arith.counter_free
######################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_counter_free.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_counter_free_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_counter_free.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_counter_free_tb.vhdl>`

Implements a free-running counter that generates a strobe signal every
DIVIDER-th cycle the increment input was asserted. There is deliberately no
output or specification of the counter value so as to allow an implementation
to optimize as much as possible.

The implementation guarantees a strobe output directly from a register. It is
asserted exactly for one clock after DIVIDER cycles of an asserted increment
input have been observed.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_counter_free.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 41-53



.. only:: latex

   Source file: :pocsrc:`arith/arith_counter_free.vhdl <arith/arith_counter_free.vhdl>`
