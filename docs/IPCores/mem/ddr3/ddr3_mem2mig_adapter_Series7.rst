
ddr3_mem2mig_adapter_Series7
############################

Adapter between the :doc:`PoC.Mem </References/Interfaces/Memory>`
interface and the application interface ("app")
of the Xilinx MIG IP core for 7-Series	FPGAs.

Simplifies the application interface ("app") of the Xilinx MIG IP core.
The PoC.Mem interface provides single-cycle fully pipelined read/write access
to the memory. All accesses are word-aligned. Always all bytes of a word are
written to the memory. More details can be found
:doc:`here </References/Interfaces/Memory>`.

Generic parameters:

* D_BITS: Data bus width of the PoC.Mem and "app" interface. Also size of one
  word in bits.

* DQ_BITS: Size of data bus between memory controller and external memory
  (DIMM, SoDIMM).

* MEM_A_BITS: Address bus width of the PoC.Mem interface.

* APP_A_BTIS: Address bus width of the "app" interface.

Containts only combinational logic.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ddr3/ddr3_mem2mig_adapter_Series7.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 61-96

Source file: `mem/ddr3/ddr3_mem2mig_adapter_Series7.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ddr3/ddr3_mem2mig_adapter_Series7.vhdl>`_



