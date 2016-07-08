
ocram_sp
########

Inferring / instantiating single-port RAM
- single clock, clock enable
- 1 read/write port
Written data is passed through the memory and output again as read-data 'q'.
This is the normal behaviour of a single-port RAM and also known as
write-first mode or read-through-write behaviour.


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocram/ocram_sp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 52-66

Source file: `mem/ocram/ocram_sp.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocram/ocram_sp.vhdl>`_


 
