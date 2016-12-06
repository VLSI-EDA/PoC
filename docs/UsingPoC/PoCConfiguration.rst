.. _USING:PoCConfig:

.. raw:: html

   <style>kbd
   { -moz-border-radius:3px;
     -moz-box-shadow:0 1px 0 rgba(0,0,0,0.2),0 0 0 2px #fff inset;
     -webkit-border-radius:3px;
     -webkit-box-shadow:0 1px 0 rgba(0,0,0,0.2),0 0 0 2px #fff inset;
     background-color:#f7f7f7;
     border:1px solid #ccc;
     border-radius:3px;
     box-shadow:0 1px 0 rgba(0,0,0,0.2),0 0 0 2px #fff inset;
     color:#333;
     display:inline-block;
     font-family:Arial,Helvetica,sans-serif;
     font-size:11px;
     line-height:1.4;
     margin:0 .1em;
     padding:.1em .6em;
     text-shadow:0 1px 0 #fff;
   }</style>

.. |kbd-Y| raw:: html

           <kbd>Y</kbd>

.. |kbd-N| raw:: html

           <kbd>N</kbd>

.. |kbd-P| raw:: html

           <kbd>P</kbd>

.. |kbd-Return| raw:: html

                <kbd>Return</kbd>

Configuring PoC's Infrastructure
################################

To explore PoC's full potential, it's required to configure some paths and
synthesis or simulation tool chains. It's possible to relaunch the process
at any time, for example to register new tools or to update tool versions.

.. contents:: Contents of this page
   :local:
   :depth: 2


.. _USING:PoCConf:Over:

Overview
========

The setup process is started by invoking PoC's frontend script with the command
``configure``. Please follow the instructions on screen. Use the keyboard
buttons: |kbd-Y| to accept, |kbd-N| to decline, |kbd-P| to skip/pass a step and
|kbd-Return| to accept a default value displayed in brackets.

Optionally, a vendor or tool chain name can be passed to the configuration
process to launch only its configuration routines.

**On Linux:**

.. code-block:: Bash

   cd ProjectRoot
   ./lib/PoC/poc.sh configure
   # with tool chain name
   ./lib/PoC/poc.sh configure Xilinx.Vivado

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
   # with tool chain name
   .\lib\PoC\poc.ps1 configure Xilinx.Vivado


**Introduction screen:**

.. code-block:: none

   PS D:\git\PoC> .\poc.ps1 configure
   ================================================================================
                            The PoC-Library - Service Tool
   ================================================================================
   Explanation of abbreviations:
     Y - yes      P        - pass (jump to next question)
     N - no       Ctrl + C - abort (no changes are saved)
   Upper case or value in '[...]' means default value
   --------------------------------------------------------------------------------

   Configuring PoC
     PoC version: v1.0.1 (found in git)
     Installation directory: D:\git\PoC (found in environment variable)


.. _USING:PoCConf:PoC:

The PoC-Library
===============
PoC itself has a fully automated configuration routine. It detects if PoC is
under Git control. If so, it extracts the current version number from the latest
Git tag. The installation directory is infered from ``$PoCRootDirectory`` setup
by ``PoC.ps1`` or ``poc.sh``.

.. code-block:: none

   Configuring PoC
     PoC version: v1.0.1 (found in git)
     Installation directory: D:\git\PoC (found in environment variable)


.. _USING:PoCConf:Git:

Git
===
.. NOTE::
   Setting up Git and Git developer settings, is an advanced feature recommended
   for all developers interrested in providing Git pull requests or patches.

.. code-block:: none

   Configuring Git
     Git installation directory [C:\Program Files\Git]:
     Install Git mechanisms for PoC developers? [y/N/p]: y
     Install Git filters? [Y/n/p]:
     Installing Git filters...
     Install Git hooks? [Y/n/p]:
     Installing Git hooks...
     Setting 'pre-commit' hook for PoC...


.. _USING:PoCConf:Aldec:

Aldec
=====
Configure the installation directory for all Aldec tools.

.. code-block:: none

   Configuring Aldec
     Are Aldec products installed on your system? [Y/n/p]: Y
     Aldec installation directory [C:\Aldec]:

Active-HDL
----------
.. code-block:: none

   Configuring Aldec Active-HDL
     Is Aldec Active-HDL installed on your system? [Y/n/p]: Y
     Aldec Active-HDL version [10.3]:
     Aldec Active-HDL installation directory [C:\Aldec\Active-HDL]: C:\Aldec\Active-HDL-Student-Edition


.. _USING:PoCConf:Altera:

Altera
======
Configure the installation directory for all Altera tools.

.. code-block:: none

	 Configuring Altera
     Are Altera products installed on your system? [Y/n/p]: Y
     Altera installation directory [C:\Altera]:

Quartus
-------
.. code-block:: none

   Configuring Altera Quartus
     Is Altera Quartus-II or Quartus Prime installed on your system? [Y/n/p]: Y
     Altera Quartus version [15.1]: 16.0
     Altera Quartus installation directory [C:\Altera\16.0\quartus]:

ModelSim Altera Edition
-----------------------
.. code-block:: none

   Configuring ModelSim Altera Edition
     Is ModelSim Altera Edition installed on your system? [Y/n/p]: Y
     ModelSim Altera Edition installation directory [C:\Altera\15.0\modelsim_ae]: C:\Altera\16.0\modelsim_ase


.. _USING:PoCConf:Lattice:

Lattice
========
Configure the installation directory for all Lattice Semiconductor tools.

.. code-block:: none

   Configuring Lattice
     Are Lattice products installed on your system? [Y/n/p]: Y
     Lattice installation directory [D:\Lattice]:

Diamond
-------
.. code-block:: none

   Configuring Lattice Diamond
     Is Lattice Diamond installed on your system? [Y/n/p]: >
     Lattice Diamond version [3.7]:
     Lattice Diamond installation directory [D:\Lattice\Diamond\3.7_x64]:

Active-HDL Lattice Edition
--------------------------
.. code-block:: none

   Configuring Active-HDL Lattice Edition
     Is Aldec Active-HDL installed on your system? [Y/n/p]: Y
     Active-HDL Lattice Edition version [10.2]:
     Active-HDL Lattice Edition installation directory [D:\Lattice\Diamond\3.7_x64\active-hdl]:


.. _USING:PoCConf:Mentor:

Mentor Graphics
===============
Configure the installation directory for all mentor Graphics tools.

.. code-block:: none

   Configuring Mentor
     Are Mentor products installed on your system? [Y/n/p]: Y
     Mentor installation directory [C:\Mentor]:

QuestaSim
---------
.. code-block:: none

   Configuring Mentor QuestaSim
     Is Mentor QuestaSim installed on your system? [Y/n/p]: Y
     Mentor QuestaSim version [10.4d]: 10.4c
     Mentor QuestaSim installation directory [C:\Mentor\QuestaSim\10.4c]: C:\Mentor\QuestaSim64\10.4c


.. _USING:PoCConf:Xilinx:

Xilinx
======
Configure the installation directory for all Xilinx tools.

..
   If Xilinx products are available and they shall be configured in PoC, then
   answer the following questions:

.. code-block:: none

   Configuring Xilinx
     Are Xilinx products installed on your system? [Y/n/p]: Y
     Xilinx installation directory [C:\Xilinx]:

ISE
---
If an Xilinx ISE environment is available and shall be configured in PoC, then
answer the following questions:

.. code-block:: none

   Configuring Xilinx ISE
     Is Xilinx ISE installed on your system? [Y/n/p]: Y
     Xilinx ISE installation directory [C:\Xilinx\14.7\ISE_DS]:

Vivado
------
If an Xilinx ISE environment is available and shall be configured in PoC, then
answer the following questions:

.. code-block:: none

   Configuring Xilinx Vivado
     Is Xilinx Vivado installed on your system? [Y/n/p]: Y
     Xilinx Vivado version [2016.2]:
     Xilinx Vivado installation directory [C:\Xilinx\Vivado\2016.2]:


.. _USING:PoCConf:GHDL:

GHDL
====
.. code-block:: none

   Configuring GHDL
     Is GHDL installed on your system? [Y/n/p]: Y
     GHDL installation directory [C:\Tools\GHDL\0.34dev]:


.. _USING:PoCConf:GTKWave:

GTKWave
========
.. code-block:: none

   Configuring GTKWave
     Is GTKWave installed on your system? [Y/n/p]: Y
     GTKWave installation directory [C:\Tools\GTKWave\3.3.71]:


.. _USING:PoCConf:HookFiles:

Hook Files
==========

PoC's wrapper scripts can be customized through pre- and post-hook file. See
:doc:`Wrapper Script Hook Files </References/WrapperScriptHookFiles>` for
more details.

