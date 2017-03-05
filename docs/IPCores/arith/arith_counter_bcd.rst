.. _IP:arith_counter_bcd:

PoC.arith.counter_bcd
#####################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_counter_bcd.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_counter_bcd_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_counter_bcd.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_counter_bcd_tb.vhdl>`

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



.. only:: latex

   Source file: :pocsrc:`arith/arith_counter_bcd.vhdl <arith/arith_counter_bcd.vhdl>`
