
Introduction
############

.. contents:: Contents of this Page

What is PoC?
************

PoC - "Pile of Cores" provides implementations for often required hardware functions such as FIFOs, RAM wrapper, and ALUs. The hardware modules are typically
provided as VHDL or Verilog source code, so it can be easily re-used in a variety of hardware designs.

.. rubric:: The PoC-Library has the following goals:

* independenability
* generics implementations
* efficient, resource 'schonend' and fast implementations
* optimized for several target architectures if suitable

.. rubric:: PoC's independancies:

* platform independenability on the host system: Darwin, Linux or Windows
* target independenability on the device target: ASIC or FPGA
* vendor independenability on the device vendor: Altera, Lattice, Xilinx, ...
* tool chain independenability for simulation and synthesis tool chains


Why should I use PoC?
*********************

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor
sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet


Which Tool Chains are supported?
********************************

The PoC-Library and its Python Infrastructure currently supports the following free and commercial vendor tool chains:

* Synthesis Tool Chains:

  * **Altera Quartus** |br|
    Tested with Quartus-II ≥13.0. |br|
    Tested with Quartus Prime ≥15.1.
  
  * **Lattice Diamond** |br|
    Tested with Diamond ≥3.6.
  
  * **Xilinx ISE** |br|
    Only ISE 14.7 inclusive Core Generator 14.7 is supported.
    
  * **Xilinx PlanAhead** |br|
    Only PlanAhead 14.7 is supported.
    
  * **Xilinx Vivado** |br|
    Tested with Vivado ≥2015.4. |br|
    Due to a limited VHDL language support compared to ISE 14.7, some PoC IP cores need special work arounds. See the synthesis documention section for Vivado for more details.


* Simulation Tool Chains:

  * **Aldec Active-HDL** |br|
    Tested with Active-HDL Student-Edition 10.3 |br|
    Tested with Active-HDL Lattice Edition 10.2
    
  * **Cocotb with Mentor QuestaSim backend** |br|
    Tested with Mentor QuestaSim 10.4d
    
  * **Mentor Graphics QuestaSim/ModelSim** |br|
    Tested with ModelSim Altera Edition 10.3d and ModelSim Altera Starter Edition 10.3d |br|
    Tested with Mentor QuestaSim 10.4d
    
  * **Xilinx ISE Simulator** |br|
    Tested with ISE Simulator (iSim) 14.7. |br|
    The Python infrastructure supports isim, but PoC's simulation helper packages and testbenches rely on VHDL-2008 features, which are not supported by isim.
    
  * **Xilinx Vivado Simulator** |br|
    Tested with Vivado Simulator (xsim) ≥2016.1. |br|
    The Python infrastructure supports xsim, but PoC's simulation helper packages and testbenches rely on VHDL-2008 features, which are not fully supported by xsim, yet.
  	
  * **GHDL** + **GTKWave** |br|
    Tested with `GHDL <https://sourceforge.net/projects/ghdl-updates/>`_ ≥0.34dev and `GTKWave <http://gtkwave.sourceforge.net/>`_ ≥3.3.70 |br|
    Due to ungoing development and bugfixes, we encourage to use the newest GHDL version.


Who uses PoC?
*************

PoC has a related Git repository called `PoC-Examples <https://github.com/VLSI-EDA/PoC-Examples>`_ on GitHub. This repository hosts a list of example and
reference implementations of the PoC-Library. Additional to reading an IP cores documention and viewing its characteristic stimulus waveform in a simulation, it
can helper to investigate an IP core usage example from that repository.

* `The Q27 Project <https://github.com/preusser/q27>`_ |br|
  27-Queens Puzzle: Massively Parellel Enumeration and Solution Counting
  
* `PicoBlaze-Library <https://github.com/Paebbels/PicoBlaze-Library>`_ |br|
  The PicoBlaze-Library offers several PicoBlaze devices and code routines to extend a common PicoBlaze environment to a little System on a Chip (SoC or SoFPGA).
  
* `PicoBlaze-Examples <https://github.com/Paebbels/PicoBlaze-Examples>`_ |br|
  A SoFPGA reference implementation, based on the PoC-Library and the PicoBlaze-Library.

