
ocrom_dp
########

Inferring / instantiating dual-port read-only memory, with:
* dual clock, clock enable,
* 2 read ports.
The generalized behavior across Altera and Xilinx FPGAs since
Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:
WARNING: The simulated behavior on RT-level is not correct.
TODO: add timing diagram
TODO: implement correct behavior for RT-level simulation


.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ocrom/ocrom_dp.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 60-76

Source file: `mem/ocrom/ocrom_dp.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ocrom/ocrom_dp.vhdl>`_


 
