
Configuring Details
###################

To explore PoC's full potential, it's required to configure some paths and
synthesis or simulation tool chains. It's possible to relaunch the process
at any time, for example to register new tools or to update tool versions.

.. contents:: Contents of this page
   :local:
   :depth: 2


Launching the Configuration
***************************

The setup process is started by invoking PoC's frontend script with the command
``configure``. Please follow the instructions on screen. Use the keyboard
buttons: :kbd:`Y` to accept, :kbd:`N` to decline, :kbd:`P` to skip/pass a step
and :kbd:`Return` to accept a default value displayed in brackets.

**On Linux:**

.. code-block:: Bash
   
   cd <ProjectRoot>
   cd lib/PoC/
   ./poc.sh configure

**On OS X**

Please see the Linux instructions.

**On Windows**

.. NOTE::
   
   All Windows command line instructions are intended for :program:`Windows PowerShell`,
   if not marked otherwise. So executing the following instructions in Windows
   Command Prompt (:program:`cmd.exe`) won't function or result in errors! See
   the :doc:`Requirements section </QuickStart/Requirements>` on where to
   download or update PowerShell.

.. code-block:: Bash
   
   cd <ProjectRoot>
   cd lib\PoC\
   .\poc.ps1 configure

**Introduction screen:**

.. code-block:: none
   
   PS D:\git\PoC> .\poc.ps1 configure
   ================================================================================
                            The PoC-Library - Service Tool
   ================================================================================
   Explanation of abbreviations:
     y - yes
     n - no
     p - pass (jump to next question)
   Upper case means default value
   
   Configuring PoC
     PoC version: v1.0.0 (found in git)
     Installation directory: D:\git\PoC (found in environment variable)

The PoC-Library
===============

The PoC-Library configuration is automatic. The current version is read from
git and the installation directory is taken from the frontend scripts location.

Aldec
=====


Active-HDL
----------

Altera
======

Quartus
-------

ModelSim Altera Edition
-----------------------

Lattice
=======

Diamond
-------

Active-HDL Lattice Edition
--------------------------

Mentor Graphics
===============

QuestaSim
---------

.. TODO::
   Is Questa-SIM installed on your system? [Y/n/p]: y
   Questa-SIM Installation Directory [C:\Mentor\QuestaSim64\10.2c]: C:\Mentor\QuestaSim64\10.3
   Questa-SIM Version Number [10.2c]: 10.3

Xilinx
======

ISE
---

.. TODO::
   If an Xilinx ISE environment is available and shall be configured in PoC, then answer the
   following questions:
   
     Is Xilinx ISE installed on your system? [Y/n/p]: y
     Xilinx Installation Directory [C:\Xilinx]: C:\Xilinx
     Xilinx ISE Version Number [14.7]: 14.7

Vivado
------

.. TODO::
   Is Xilinx Vivado installed on your system? [Y/n/p]: y
   Xilinx Installation Directory [C:\Xilinx]: C:\Xilinx
   Xilinx Vivado Version Number [2014.4]: 2015.2

GHDL
====

.. TODO::
   Is GHDL installed on your system? [Y/n/p]: y
   GHDL Installation Directory [C:\Program Files (x86)\GHDL]: C:\Tools\GHDL\0.33dev
   GHDL Version Number [0.31]: 0.33

GTKWave
=======

.. TODO::
   Is GTKWave installed on your system? [Y/n/p]: y
   GTKWave Installation Directory [C:\Program Files (x86)\GTKWave]: C:\Tools\GTKWave\3.3.66
   GTKWave Version Number [3.3.61]: 3.3.66



Creating PoC's my_config and my_project Files
*********************************************

The PoC-Library needs two VHDL files for it's configuration. These files are
used to determine the most suitable implementation depending on the provided
platform information. These files are also used to select appropiate work
arounds.

1. The **my_config** file can easily be created from a template file provided
   by PoC in ``<PoCRoot>\src\common\my_config.vhdl.template``.

   The file should to be copyed into a projects source directory and renamed
   into ``my_config.vhdl``. This file should be included into version control
   systems and shared with other systems. ``my_config.vhdl`` defines three
   global constants, which need to be adjusted:

   .. code-block:: VHDL
	    
	    constant MY_BOARD   : string   := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
	    constant MY_DEVICE  : string   := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3
	    constant MY_VERBOSE : boolean  := FALSE;         -- activate detailed report statements in functions and procedures

   The easiest way is to define a board name and set ``MY_DEVICE`` to ``None``.
   So the device name is infered from the board information stored in ``<PoCRoot>\src\common\board.vhdl``.
   If the requested board is not known to PoC or it's custom made, then set
   ``MY_BOARD`` to ``Custom`` and ``MY_DEVICE`` to the full FPGA device string.

   **Example 1: A "Stratix II GX Audio Video Development Kit" board:**

   .. code-block:: VHDL
	    
	    constant MY_BOARD  : string	:= "S2GXAV";  -- Stratix II GX Audio Video Development Kit
	    constant MY_DEVICE : string	:= "None";    -- infer from MY_BOARD

   **Example 2: A custom made Spartan-6 LX45 board:**

   .. code-block:: VHDL
	    
	    constant MY_BOARD  : string	:= "Custom";
	    constant MY_DEVICE : string	:= "XC6SLX45-3CSG324";

2. The **my_project** file can also be created from a template provided by PoC
   in ``<PoCRoot>\src\common\my_project.vhdl.template``.
   
   The file should to be copyed into a projects source directory and renamed
   into ``my_project.vhdl``. This file **must not** be included into version
   control systems - it's private to a host computer. ``my_project.vhdl``
   defines two global constants, which need to be adjusted:

   .. code-block:: VHDL
	    
	    constant MY_PROJECT_DIR       : string  := "CHANGE THIS";   -- e.g. "d:/vhdl/myproject/", "/home/me/projects/myproject/"
      constant MY_OPERATING_SYSTEM  : string  := "CHANGE THIS";   -- e.g. "WINDOWS", "LINUX"

   **Example 1: A Windows System:**
   
   .. code-block:: VHDL
	    
	    constant MY_PROJECT_DIR       : string  := "D:/git/GitHub/PoC/";
      constant MY_OPERATING_SYSTEM  : string  := "WINDOWS";

   **Example 2: A Debian System:**

   .. code-block:: VHDL
	    
	    constant MY_PROJECT_DIR       : string  := "/home/paebbels/git/GitHub/PoC/";
	    constant MY_OPERATING_SYSTEM  : string  := "LINUX";

.. seealso::
   :doc:`Running one or more testbenches </UsingPoC/Simulation>`
      The installation can be checked by running one or more of PoC's testbenches.
   :doc:`Running one or more netlist generation flows </UsingPoC/Synthesis>`
      The installation can also be checked by running one or more of PoC's
      synthesis flows.
