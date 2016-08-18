Change Log
##########

.. contents:: Content of this page
   :local:

****************************************************************************************************************************************************************
2016
****************************************************************************************************************************************************************

..  This is a comment block. Copy this block for a new release version.

    New in 1.x (upcomming)
    =======================

    Already documented changes are available on the ``release`` branch at GitHub.

    * Python Infrastructure
      * Common changes
      * All Simulators
      * Aldec Active-HDL
			* GHDL
			* Mentor QuestaSim
			* Xilinx ISE Simulator
			* Xilinx Vivado Simulator
      * All Compilers
      * Altera Quartus Synthesis
      * Lattice Diamond (LSE)
      * Xilinx ISE (XST)
      * Xilinx ISE Core Generator
      * Xilinx Vivado Synthesis
    * Documentation
    * VHDL common packages
    * VHDL Simulation helpers
    * New Entities
    * New Testbenches
    * New Constraints
    * Shipped Tool and Helper Scripts


New in 1.x (upcomming)
=======================

Already documented changes are available on the ``release`` branch at GitHub.

* Python Infrastructure

  * Common changes

    * The classes ``Simulator`` and ``Compiler`` now share common methods in base class called ``Shared``.

  * ``*.files`` Parser

    * Implemented path expressions: sub-directory expression, concatenate expression
    * Implemented InterpolateLiteral: access database keys in ``*.files`` files
    * New Path statement, which defines a path constant calculated from a path expression
    * Replaced string arguments in statements with path expressions if the desired string was a path
    * Replaced simple StringToken matches with Identifier expressions

  * All Simulators

    *

  * All Compilers

    *

  * GHDL

    * Reduced ``-P<path>`` parameters: Removed doublings

* Documentation

  *

* VHDL common packages

  *

* VHDL Simulation helpers

  * Mark a testbench as failed if (registered) processes are active while finilize is called

* New Entities

  *

* New Testbenches

  *

* New Constraints

  *

* Shipped Tool and Helper Scripts

  * Updated and new Notepad++ syntax files


New in 1.0 (13.05.2016)
================================================================================================================================================================

* Python Infrastructure (Completely Reworked)

  * New Requirements

    * Python 3.5
    * py-flags

  * New command line interface

    * Synopsis: ``poc.sh|ps1 [common options] <command> <entity> [options]``
    * Removed task specific wrapper scripts: ``testbench.sh|ps1``, ``netlist.sh|ps1``, ...
    * Updated ``wrapper.ps1`` and ``wrapper.sh`` files

  * New ini-file database

    *
    * Added a new config.boards.ini file to list known boards (real and virtual ones)

  * New parser for ``*.files`` files

    * conditional compiling (if-then-elseif-else)
    * include statement - include other ``*.files`` files
    * library statement - reference external VHDL libraries
    * prepared for Cocotb testbenches

  * New parser for ``*.rules`` files

    *

  * All Tool Flows

    * Unbuffered outputs from vendor tools (realtime output to stdout from subprocess)
    * Output filtering from vendor tools

      * verbose message suppression
      * error and warning message highlighting
      * abort flow on vendor tool errors

  * All Simulators

    * Run testbenches for different board or device configurations (see ``--board`` and ``--device`` command line options)

  * New Simulators

    * Aldec Active-HDL support (no GUI support)

      * Tested with Active-HDL from Lattice Diamond
      * Tested with Active-HDL Student-Edition

    * Cocotb (with QuestaSim backend on Linux)

  * New Synthesizers

    * Altera Quartus II and Quartus Prime

      * Command: ``quartus``

    * Lattice Synthesis Engine (LSE) from Diamond

      * Command: ``lse``

    * Xilinx Vivado

      * Command: ``vivado``

  * GHDL

    * GHDLSimulator can distinguish different backends (mcode, gcc, llvm)
    * Pre-compiled library support for GHDL

  * QuestaSim / ModelSim Altera Edition

    * Pre-compiled library support for GHDL

  * Vivado Simulator

    * Tested Vivado Simulator 2016.1 (xSim) with PoC -> still produces errors or false results

* New Entities

    *

* New Testbenches

    *

* New Constraints

    *

* New dependencies

    * Embedded Cocotb in ``<PoCRoot>/lib/cocotb``

* Shipped Tool and Helper Scripts

    * Updated and new Notepad++ syntax files
    * Pre-compiled vendor library support

        * Added a new ``<PoCRoot>/temp/precompiled`` folder for precompiled vendor libraries
        * QuestaSim supports Altera QuartusII, Xilinx ISE and Xilinx Vivado libraries
        * GHDL supports Altera QuartusII, Xilinx ISE and Xilinx Vivado libraries


New in 0.21 (17.02.2016)
================================================================================================================================================================


New in 0.20 (16.01.2016)
================================================================================================================================================================


New in 0.19 (16.01.2016)
================================================================================================================================================================

****************************************************************************************************************************************************************
2015
****************************************************************************************************************************************************************

New in 0.18 (16.12.2015)
================================================================================================================================================================


New in 0.17 (08.12.2015)
================================================================================================================================================================


New in 0.16 (01.12.2015)
================================================================================================================================================================


New in 0.15 (13.11.2015)
================================================================================================================================================================


New in 0.14 (28.09.2015)
================================================================================================================================================================


New in 0.13 (04.09.2015)
================================================================================================================================================================


New in 0.12 (25.08.2015)
================================================================================================================================================================


New in 0.11 (07.08.2015)
================================================================================================================================================================


New in 0.10 (23.07.2015)
================================================================================================================================================================


New in 0.9 (21.07.2015)
================================================================================================================================================================


New in 0.8 (03.07.2015)
================================================================================================================================================================


New in 0.7 (27.06.2015)
================================================================================================================================================================


New in 0.6 (09.06.2015)
================================================================================================================================================================


New in 0.5 (27.05.2015)
================================================================================================================================================================

* Updated Python infrastructure
* New testbenches:

  * sync_Reset_tb
  * sync_Flag_tb
  * sync_Strobe_tb
  * sync_Vector_tb
  * sync_Command_tb

* Updated modules:

  * sync_Vector
  * sync_Command

* Updated packages:

  * physical
  * utils
  * vectors
  * xil

New in 0.4 (29.04.2015)
================================================================================================================================================================

* New Python infrastructure

  * Added simulators for:

    * GHDL + GTKWave
    * Mentor Graphic QuestaSim
    * Xilinx ISE Simulator
    * Xilinx Vivado Simulator

* New packages:

  * simulation

* New modules:

  * PoC.comm - communication modules

    * comm_crc

  * PoC.comm.remote - remote communication modules

    * remote_terminal_control

* New testbenches:

  * arith_addw_tb
  * arith_counter_bcd_tb
  * arith_prefix_and_tb
  * arith_prefix_or_tb
  * arith_prng_tb

* Updated packages:

  * board
  * config
  * physical
  * strings
  * utils

* Updated modules:

  * io_Debounce
  * misc_FrequencyMeasurement
  * sync_Bits
  * sync_Reset

New in 0.3 (31.03.20015)
================================================================================================================================================================

* Added Python infrastructure

  * Added platform wrapper scripts (\*.sh, \*.ps1)
  * Added IP-core compiler scripts Netlist.py

* Added Tools

  * Notepad++ syntax file for Xilinx UCF/XCF files
  * Git configuration script to register global aliases

* New packages:

  * components - hardware described as functions
  * physical - physical types like frequency, memory and baudrate
  * io

* New modules:

  * PoC.misc

    * misc_FrequencyMeasurement

  * PoC.io - Low-speed I/O interfaces

    * io_7SegmentMux_BCD
    * io_7SegmentMux_HEX
    * io_FanControl
    * io_PulseWidthModulation
    * io_TimingCounter
    * io_Debounce
    * io_GlitchFilter

* New IP-cores:

  * PoC.xil - Xilinx specific modules

    * xil_ChipScopeICON_1
    * xil_ChipScopeICON_2
    * xil_ChipScopeICON_3
    * xil_ChipScopeICON_4
    * xil_ChipScopeICON_6
    * xil_ChipScopeICON_7
    * xil_ChipScopeICON_8
    * xil_ChipScopeICON_9
    * xil_ChipScopeICON_10
    * xil_ChipScopeICON_11
    * xil_ChipScopeICON_12
    * xil_ChipScopeICON_13
    * xil_ChipScopeICON_14
    * xil_ChipScopeICON_15

* New constraint files:

  * ML605
  * KC705
  * VC707
  * MetaStability
  * xil_Sync

* Updated packages:

  * board
  * config

* Updated modules:

  * xil_BSCAN

New in 0.2 (09.03.2015)
================================================================================================================================================================

* New packages:

  * xil
  * stream

* New modules:

  * PoC.bus - Modules for busses

    * bus_Arbiter

  * PoC.bus.stream - Modules for the PoC.Stream protocol

    * stream_Buffer
    * stream_DeMux
    * stream_FrameGenerator
    * stream_Mirror
    * stream_Mux
    * stream_Source

  * PoC.misc.sync - Cross-Clock Synchronizers

    * sync_Reset
    * sync_Flag
    * sync_Strobe
    * sync_Vector
    * sync_Command

  * PoC.xil - Xilinx specific modules

    * xil_SyncBits
    * xil_SyncReset
    * xil_BSCAN
    * xil_Reconfigurator
    * xil_SystemMonitor_Virtex6
    * xil_SystemMonitor_Series7

* Updated packages:

  * utils
  * arith

New in 0.1 (19.02.2015)
================================================================================================================================================================

* New packages:

  * board - common development board configurations
  * config - extract configuration parameters from device names
  * utils - common utility functions
  * strings - a helper package for string handling
  * vectors - a helper package for std_logic_vector and std_logic_matrix
  * arith
  * fifo

* New modules

  * PoC.arith - arithmetic modules

    * arith_counter_gray
    * arith_counter_ring
    * arith_div
    * arith_prefix_and
    * arith_prefix_or
    * arith_prng
    * arith_scaler
    * arith_sqrt

  * PoC.fifo - FIFOs

    * fifo_cc_got
    * fifo_cc_got_tempgot
    * fifo_cc_got_tempput
    * fifo_ic_got
    * fifo_glue
    * fifo_shift

  * PoC.mem.ocram - On-Chip RAMs

    * ocram_sp
    * ocram_sdp
    * ocram_esdp
    * ocram_tdp
    * ocram_wb

****************************************************************************************************************************************************************
2014
****************************************************************************************************************************************************************

New in 0.0 (16.12.2014)
================================================================================================================================================================

* Initial commit
