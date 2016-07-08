
arith_prefix_or
###############

Prefix OR computation:
``y(i) <= '0' when x(i downto 0) = (i downto 0 => '0') else '1';``
This implementation uses carry chains for wider implementations.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_prefix_or.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 43-51

Source file: `arith/arith_prefix_or.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_prefix_or.vhdl>`_


 
