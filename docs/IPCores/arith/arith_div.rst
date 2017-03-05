.. _IP:arith_div:

PoC.arith.div
#############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_div.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_div_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_div.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_div_tb.vhdl>`

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



.. only:: latex

   Source file: :pocsrc:`arith/arith_div.vhdl <arith/arith_div.vhdl>`
