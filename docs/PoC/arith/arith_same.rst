
arith_same
##########

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

Source file: `arith/arith_same.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/arith/arith_same.vhdl>`_


	 