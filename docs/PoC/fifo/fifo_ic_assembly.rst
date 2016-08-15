
fifo_ic_assembly
################

This module assembles a FIFO stream from data blocks that may arrive
slightly out of order. The arriving data is ordered according to their
address. The streamed output starts with the data word written to
address zero (0) and may proceed all the way to just before the first yet
missing data. The association of data with addresses is used on the input
side for the sole purpose of reconstructing the correct order of the data.
It is assumed to wrap so as to allow an infinite input sequence. Addresses
are not actively exposed to the purely stream-based FIFO output.

The implemented functionality enables the reconstruction of streams that
are tunnelled across address-based transports that are allowed to reorder
the transmission of data blocks. This applies to many DMA implementations.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/fifo/fifo_ic_assembly.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 45-78

Source file: `fifo/fifo_ic_assembly.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/fifo/fifo_ic_assembly.vhdl>`_


	 