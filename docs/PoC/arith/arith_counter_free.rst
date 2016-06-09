
arith_counter_free
##################

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

Source file: `arith/arith_counter_free.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_counter_free.vhdl>`_


	 