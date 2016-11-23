.. _IP:ddr2_mem2mig_adapter_Spartan6:

PoC.mem.ddr2.mem2mig_adapter_Spartan6
#####################################

.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/ddr2/ddr2_mem2mig_adapter_Spartan6.vhdl
               :alt: Source Code on GitHub
   .. |gh-tb| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/tb/mem/ddr2/ddr2_mem2mig_adapter_Spartan6_tb.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      * |gh-src| :pocsrc:`Sourcecode <mem/ddr2/ddr2_mem2mig_adapter_Spartan6.vhdl>`
      * |gh-tb| :poctb:`Testbench <mem/ddr2/ddr2_mem2mig_adapter_Spartan6_tb.vhdl>`

Adapter between the :ref:`PoC.Mem <INT:PoC.Mem>`
interface and the User Interface of the Xilinx MIG IP core for the
Spartan-6 FPGA Memory Controller Block (MCB). The MCB can be configured to
have multiple ports. One instance of this adapter is required for every
port. The control signals for one port of the MIG IP core are prefixed by
"cX_pY", meaning port Y on controller X.

Simplifies the User Interface ("user") of the Xilinx MIG IP core (UG388).
The PoC.Mem interface provides single-cycle fully pipelined read/write access
to the memory. All accesses are word-aligned. Always all bytes of a word are
written to the memory. More details can be found
:ref:`here <INT:PoC.Mem>`.

Generic parameters:

* D_BITS: Data bus width of the PoC.Mem and MIG / MCBinterface. Also size of
  one word in bits.

* MEM_A_BITS: Address bus width of the PoC.Mem interface.

* APP_A_BTIS: Address bus width of the MIG / MCB interface.

Containts only combinational logic.



.. rubric:: Entity Declaration:

.. literalinclude:: ../../../../src/mem/ddr2/ddr2_mem2mig_adapter_Spartan6.vhdl
   :language: vhdl
   :tab-width: 2
   :linenos:
   :lines: 61-96



.. only:: latex

   Source file: :pocsrc:`mem/ddr2/ddr2_mem2mig_adapter_Spartan6.vhdl <mem/ddr2/ddr2_mem2mig_adapter_Spartan6.vhdl>`
