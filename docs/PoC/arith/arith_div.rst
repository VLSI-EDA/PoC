
arith_div
#########

Implementation of a Non-Performing restoring divider with a configurable radix.
The multi-cycle division is controlled by 'start' / 'rdy'. A new division is
started by asserting 'start'. The result Q = A/D is available when 'rdy'
returns to '1'. A division by zero is identified by output Z. The Q and R
outputs are undefined in this case.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_div.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 38-61


	 