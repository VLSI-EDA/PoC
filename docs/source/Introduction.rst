What is PoC?
********************************************************************************

PoC - "Pile of Cores" provides implementations for often required hardware functions such as FIFOs, RAM wrapper, and ALUs. The hardware modules are typically
provided as VHDL or Verilog source code, so it can be easily re-used in a variety of hardware designs.

**The PoC-Library has the following goals:**

* independenability
* generics implementations
* efficient, resource 'schonend' and fast implementations
* optimized for several target architectures if suitable

**PoC's independancies:**

* platform independenability on the host system: Darwin, Linux or Windows
* target independenability on the device target: ASIC or FPGA
* vendor independenability on the device vendor: Altera, Lattice, Xilinx, ...
* tool chain independenability for simulation and synthesis tool chains

Who uses PoC?
=============

First of all, PoC has a related Git repository called `PoC-Examples <https://github.com/VLSI-EDA/PoC-Examples>`_. This repository has a list of example and
reference implementations for the PoC-Library.

`PoC-Examples on GitHub <https://github.com/VLSI-EDA/PoC-Examples>`_

* `The Q27 Project <https://github.com/preusser/q27>`_
  27-Queens Puzzle: Massively Parellel Enumeration and Solution Counting
* `PicoBlaze-Library <https://github.com/Paebbels/PicoBlaze-Library>`_
  The PicoBlaze-Library offers several PicoBlaze devices and code routines to extend a common PicoBlaze environment to a little System on a Chip (SoC or SoFPGA).
* `PicoBlaze-Examples <https://github.com/Paebbels/PicoBlaze-Examples>`_
  A SoFPGA reference implementation, based on the PoC-Library and the PicoBlaze-Library.
