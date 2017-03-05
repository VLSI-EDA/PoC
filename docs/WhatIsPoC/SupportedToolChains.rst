.. _INTRO:ToolChains:

Which Tool Chains are supported?
################################

The PoC-Library and its Python-based infrastructure currently supports the following free and commercial vendor tool chains:

* Synthesis Tool Chains:

  * **Altera Quartus** |br|
    Tested with Quartus-II |geq| 13.0. |br|
    Tested with Quartus Prime |geq| 15.1.

  * **Intel Quartus** |br|
    Tested with Quartus Prime |geq| 16.1.

  * **Lattice Diamond** |br|
    Tested with Diamond |geq| 3.6.

  * **Xilinx ISE** |br|
    Only ISE 14.7 inclusive Core Generator 14.7 is supported.

  * **Xilinx PlanAhead** |br|
    Only PlanAhead 14.7 is supported.

  * **Xilinx Vivado** |br|
    Tested with Vivado |geq| 2015.4. |br|
    Due to a limited VHDL language support compared to ISE 14.7, some PoC IP cores need special work arounds. See the synthesis documention section for Vivado for more details.


* Simulation Tool Chains:

  * **Aldec Active-HDL** |br|
    Tested with Active-HDL (or Student-Edition) |geq| 10.3 |br|
    Tested with Active-HDL Lattice Edition |geq| 10.2

  * **Cocotb with Mentor QuestaSim backend** |br|
    Tested with Mentor QuestaSim 10.4d

  * **Mentor Graphics ModelSim** |br|
    Tested with ModelSim PE (or Student Edition) |geq| 10.5c |br|
    Tested with ModelSim SE |geq| 10.5c |br|
    Tested with ModelSim Altera Edition 10.3d (or Starter Edition)

  * **Mentor Graphics QuestaSim/ModelSim** |br|
    Tested with Mentor QuestaSim |geq| 10.4d

  * **Xilinx ISE Simulator** |br|
    Tested with ISE Simulator (iSim) 14.7. |br|
    The Python infrastructure supports isim, but PoC's simulation helper packages and testbenches rely on VHDL-2008 features, which are not supported by isim.

  * **Xilinx Vivado Simulator** |br|
    Tested with Vivado Simulator (xsim) |geq| 2016.3. |br|
    The Python infrastructure supports xsim, but PoC's simulation helper packages and testbenches rely on VHDL-2008 features, which are not fully supported by xsim, yet.

  * **GHDL** + **GTKWave** |br|
    Tested with `GHDL <https://github.com/tgingold/ghdl/>`_ |geq| 0.34dev and `GTKWave <http://gtkwave.sourceforge.net/>`_ |geq| 3.3.70 |br|
    Due to ungoing development and bugfixes, we encourage to use the newest GHDL version.
