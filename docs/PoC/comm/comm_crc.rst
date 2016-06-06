
comm_crc
########

Computes the Cyclic Redundancy Check (CRC) for a data packet as remainder
of the polynomial division of the message by the given generator
polynomial (GEN).

The computation is unrolled so as to process an arbitrary number of
message bits per step. The generated CRC is independent from the chosen
processing width.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../src/comm/comm_crc.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 45-64


	 