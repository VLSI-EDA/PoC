.. _IP:arith_same:

PoC.arith.same
##############

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_same.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/arith/arith_same_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <arith/arith_same.vhdl>`
      * |gh-tb| :poctb:`Testbench <arith/arith_same_tb.vhdl>`

This circuit may, for instance, be used to detect the first sign change
and, thus, the range of a two's complement number.

These components may be chained by using the output of the predecessor as
guard input. This chaining allows to have intermediate results available
while still ensuring the use of a fast carry chain on supporting FPGA
architectures. When chaining, make sure to overlap both vector slices by one
bit position as to avoid an undetected sign change between the slices.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/arith/arith_same.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 48-57



.. only:: latex

   Source file: :pocsrc:`arith/arith_same.vhdl <arith/arith_same.vhdl>`
