
fifo_glue
#########

Its primary use is the decoupling of enable domains in a processing
pipeline. Data storage is limited to two words only so as to allow both
the ``ful``  and the ``vld`` indicators to be driven by registers.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/fifo/fifo_glue.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 36-55

Source file: `fifo/fifo_glue.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/fifo/fifo_glue.vhdl>`_


 
