
arith_counter_ring
##################

This module implements an up/down ring-counter with loadable initial value
(``seed``) on reset. The counter can be configured to a Johnson counter by
enabling ``INVERT_FEEDBACK``. The number of counter bits is configurable with
``BITS``.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_counter_ring.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 41-54

Source file: `arith/arith_counter_ring.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_counter_ring.vhdl>`_


 
