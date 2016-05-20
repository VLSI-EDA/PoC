Using PoC
*********

**The PoC-Library** is structured into several sub-folders naming the purpose of the folder like `src <https://github.com/VLSI-EDA/PoC/tree/master/src>`_ for
sources files or `tb <https://github.com/VLSI-EDA/PoC/tree/master/tb>`_ for testbench files. The structure within these folders is always the same and based on
PoC's [sub-namespace tree].

**Main directory overview:**

* `lib <https://github.com/VLSI-EDA/PoC/tree/master/lib>`_ - Embedded or linked external libraries.
* `netlist <https://github.com/VLSI-EDA/PoC/tree/master/netlist>`_ - Configuration files and output directory for pre-configured netlist synthesis results from
  vendor IP cores or from complex PoC controllers.
* `py <https://github.com/VLSI-EDA/PoC/tree/master/py>`_ - Supporting Python scripts.
* `sim <https://github.com/VLSI-EDA/PoC/tree/master/sim>`_ - Pre-configured waveform views for selected testbenches.
* `src <https://github.com/VLSI-EDA/PoC/tree/master/src>`_ - PoC's source files grouped into sub-folders according to the [sub-namespace tree]
* `tb <https://github.com/VLSI-EDA/PoC/tree/master/tb>`_ - Testbench files.
* `tcl <https://github.com/VLSI-EDA/PoC/tree/master/tcl>`_ - Tcl files.
* `temp <https://github.com/VLSI-EDA/PoC/tree/master/temp>`_ - A created temporary directors for various tools used by PoC's Python scripts.
* `tools <https://github.com/VLSI-EDA/PoC/tree/master/tools>`_ - Settings/highlighting files and helpers for supported tools.
* `ucf <https://github.com/VLSI-EDA/PoC/tree/master/ucf>`_ - Pre-configured constraint files (\*.ucf, \*.xdc, \*.sdc) for supported FPGA boards.
* `xst <https://github.com/VLSI-EDA/PoC/tree/master/xst>`_ - Configuration files to synthesize PoC modules with Xilinx XST into a netlist.

Common Notes
================

All VHDL source files should be compiled into the VHDL library ``PoC``. If not indicated otherwise, all source files can be compiled using the VHDL-93 or
VHDL-2008 language version. Incompatible files are named ``*.v93.vhdl`` and ``*.v08.vhdl`` to denote the highest supported language version.

Standalone
==============

In Altera Quartus II
========================

In GHDL
===========

In ModelSim/QuestaSim
=========================


In Xilinx ISE (XST and iSim)
================================

**The PoC-Library** was originally designed for the Xilinx ISE design flow. The latest version (14.7) is supported and required to explore PoC's full potential.
Don't forget to activate the new XST parser in new projects and to append the IP core search directory if generated netlists are used.

# **Activating the New Parser in XST**
  PoC requires XST to use the *new* source file parser, introduced
  with the Virtex-6 FPGA family. It is backward compatible.

  **->** Open the *XST Process Property* window and add ``-use_new_parser yes``
  to the option ``Other XST Command Line Options``.

# **Setting the IP Core Search Directory for Generated Netlists**
  PoC can generate netlists for bundled source files or for
  pre-configured IP cores. These netlists are copied into the
  ``<PoCRoot>\netlist\<DEVICE>`` folder. This folder and its subfolders
  need to be added to the IP core search directory.
    
  **->** Open the *XST Process Property* window and append the directory to the ``-sd`` option.
  **->** Open *Translate Process Property* and append the paths here, too. ::
    
      D:\git\PoC\netlist\XC7VX485T-2FFG1761|      ↩
      D:\git\PoC\netlist\XC7VX485T-2FFG1761\xil|  ↩
      D:\git\PoC\netlist\XC7VX485T-2FFG1761\sata

  **Note:** The IP core search directory value is a ``|`` seperated list of directories. A recursive search is not performed, so sub-folders need to be named
  individually.

In Xilinx Vivado (Synth and xSim)
=====================================

**The PoC-Library** has no full Vivado support, because of the incomplete VHDL-93 support in Vivado's synthesis tool. Especially the incorrect implementation of
physical types causes errors in PoC's I/O modules.

Vivado's simulator xSim is not affected.

**Experimental ``Vivado`` Branch:**
We provide a ``vivado`` branch, which can be used for Vivado synthesis. This branch contains workarounds to let Vivado synthesize our modules. As an effect some
interfaces (mostly generics have changed).
