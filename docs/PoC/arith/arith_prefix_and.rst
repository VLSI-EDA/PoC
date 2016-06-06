
arith_prefix_and
################

Prefix AND computation:
``y(i) <= '1' when x(i downto 0) = (i downto 0 => '1') else '0';``
This implementation uses carry chains for wider implementations.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_prefix_and.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 43-51


	 