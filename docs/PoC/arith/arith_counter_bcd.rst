
arith_counter_bcd
#################

Counter with output in binary coded decimal (BCD). The number of BCD digits
is configurable by ``DIGITS``.

All control signals (reset ``rst``, increment ``inc``) are high-active and
synchronous to clock ``clk``. The output ``val`` is the current counter
state. Groups of 4 bit represent one BCD digit. The lowest significant digit
is specified by ``val(3 downto 0)``.

.. TODO::
   
   * implement a ``dec`` input for decrementing
   * implement a ``load`` input to load a value


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_counter_bcd.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 51-61


	 