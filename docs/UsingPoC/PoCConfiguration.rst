
Configuring PoC's Infrastructure
################################

To explore PoC's full potential, it's required to configure some paths and
synthesis or simulation tool chains. It's possible to relaunch the process
at any time, for example to register new tools or to update tool versions.

.. contents:: Contents of this page
   :local:
   :depth: 2


Overview
========

The setup process is started by invoking PoC's frontend script with the command
``configure``. Please follow the instructions on screen. Use the keyboard
buttons: :kbd:`Y` to accept, :kbd:`N` to decline, :kbd:`P` to skip/pass a step
and :kbd:`Return` to accept a default value displayed in brackets.

**On Linux:**

.. code-block:: Bash
   
   cd ProjectRoot
   ./lib/PoC/poc.sh configure


**On OS X**

Please see the Linux instructions.


**On Windows**

.. NOTE::
   
   All Windows command line instructions are intended for :program:`Windows PowerShell`,
   if not marked otherwise. So executing the following instructions in Windows
   Command Prompt (:program:`cmd.exe`) won't function or result in errors! See
   the :doc:`Requirements section </UsingPoC/Requirements>` on where to
   download or update PowerShell.

.. code-block:: PowerShell
   
   cd ProjectRoot
   .\lib\PoC\poc.ps1 configure


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
     PoC version: v1.0.1 (found in git)
     Installation directory: D:\git\PoC (found in environment variable)


The PoC-Library
===============

The PoC-Library configuration is automatic. The current version is read from
Git and the installation directory is taken from the frontend scripts location.

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
