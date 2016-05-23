
Synthesis
#########

The Python Infrastructure shipped with the PoC-Library can launch manual,
half-automated and fully automated synthesis runs. This can be done by invoking
one of PoC's frontend script:

* **poc.sh:** ``poc.sh <common options> <compiler> <module> <compiler options>`` |br|
  Use this fronend script on Darwin, Linux and Unix platforms.
* **poc.ps1:** ``poc.ps1 <common options> <compiler> <module> <compiler options>`` |br|
  Use this frontend script Windows platforms. |br|
  
  .. ATTENTION::
     All Windows command line instructions are intended for Windows
     PowerShell, if not marked otherwise. So executing the following instructions
     in Windows Command Prompt (``cmd.exe``) won't function or result in errors!

.. seealso::
   
   :doc:`Supported Compiler </WhatIsPoC/SupportedToolChains>`
     See the Intruction page for a list of supported compilers.
   :doc:`PoC Configuration </QuickStart/Configuration>`
     See the Configuration page on how to configure PoC and your installed
     synthesis tool chains. This is required to invoke the compilers.


Quick Example
*************

The following quick example uses the Xilinx Systesis Tool (XST) to synthesize a
netlist for IP core ``arith_prng`` (Pseudo Random Number Generator - PRNG). The
VHDL file ``arith_prng.vhdl`` is located at ``<PoCRoot>/src/arith/`` and
virtually a member in the `PoC.arith` namespace. So the module can be identified
by an unique name: ``PoC.arith.prng``, which is passed to the frontend script.

.. rubric:: Example 1:

.. code-block:: PowerShell
   
   cd <PoCRoot>
   .\poc.ps1 xst PoC.arith.prng --board=KC705

The CLI command ``xst`` chooses *Xilinx Synthesis Tool* as the synthesizer and
passes the fully qualified PoC entity name ``PoC.arith.prng`` as a parameter
to the tool. Additionally, the development board name is required to load the
correct ``my_config.vhdl`` file. All required source file are gathered and
synthesized to a netlist.


Unnamed Headline
****************

Special Development Board Names
===============================

+--------------+--------------+-----------------+
| Board Name   | Target Board | Target Device   |
+==============+==============+=================+
| GENERIC      | GENERIC      | GENERIC         |
+--------------+--------------------------------+
| Altera       | DE4          | Stratix-IV 230  |
+--------------+--------------------------------+
| Lattice      | ECP5Versa    | ECP5-45UM       |
+--------------+--------------------------------+
| Xilinx       | KC705        | Kintex-7 325T   |
+--------------+--------------------------------+

.. seealso::
   List of Supported Target Devices
	    xxxx
   List of Supported Development Boards
      xxxx


Running a single Synthesis
**************************

A synthesis run is supervised by PoC's ``<PoCRoot>\py\PoC.py`` service tool,
which offers a consistent interface to all synthesizers. Unfortunately, every
platform has it's specialties, so a wrapper script is needed as abstraction from
the host's operating system. Depending on the choosen tool chain, the wrapper
script will source or invoke the vendor tool's environment scripts to pre-load
the needed environment variables, paths or license file settings.

The order of options to the frontend script is as following:
``<common options> <compiler> <module> <compiler options>``

The frontend offers several common options:

+-----------------+-------------------------------+
| Common Option   | Description                   |
+=====+===========+===============================+
| -q  | --quiet   | Quiet-mode (print nothing)    |
+-----+-----------+-------------------------------+
| -v  | --verbose | Print more messages           |
+-----+-----------+-------------------------------+
| -d  | --debug   | Debug mode (print everything) |
+-----+-----------+-------------------------------+
|     | --dryrun  | Run in dry-run mode           |
+-----+-----------+-------------------------------+

One of the following supported synthesizers can be choosen, if installed and
configured in PoC:

+-----------+--------------------------------------------------+
| Simulator | Description                                      |
+===========+==================================================+
| quartus   | Altera Quartus II or Quartus Prime               |
+-----------+--------------------------------------------------+
| lse       | Lattice Diamond - Lattice Synthesis Engine (LSE) |
+-----------+--------------------------------------------------+
| xst       | Xilinx ISE Systhesis Tool (XST)                  |
+-----------+--------------------------------------------------+
| coregen   | Xilinx ISE Core Generator (CoreGen)              |
+-----------+--------------------------------------------------+
| vivado    | Xilinx Vivado Synthesis                          |
+-----------+--------------------------------------------------+


Altera Quartus
==============

The command to invoke a synthesis using Altera Quartus II or Quartus Prime is
``quartus`` followed by a list of PoC entities. The following options are
supported for Quartus:

+--------------------------+---------------------------------------------------------+
| Simulator Option         | Description                                             |
+====+=====================+=========================================================+
|    | --board=<BOARD>     | Specify a target board.                                 |
+----+---------------------+---------------------------------------------------------+
|    | --device=<DEVICE>   | Specify a target device.                                |
+----+---------------------+---------------------------------------------------------+

.. rubric:: Example:

.. code-block:: PowerShell

   cd <PoCRoot>
   .\poc.ps1 quartus PoC.arith.prng --board=DE4


Lattice Diamond
===============

The command to invoke a synthesis using Altera Quartus II or Quartus Prime is
``quartus`` followed by a list of PoC entities. The following options are
supported for Quartus:

+--------------------------+---------------------------------------------------------+
| Simulator Option         | Description                                             |
+====+=====================+=========================================================+
|    | --board=<BOARD>     | Specify a target board.                                 |
+----+---------------------+---------------------------------------------------------+
|    | --device=<DEVICE>   | Specify a target device.                                |
+----+---------------------+---------------------------------------------------------+

.. rubric:: Example:

.. code-block:: PowerShell

   cd <PoCRoot>
   .\poc.ps1 quartus PoC.arith.prng --board=DE4


Xilinx ISE Synthesis Tool (XST)
===============================

The command to invoke a synthesis using Altera Quartus II or Quartus Prime is
``quartus`` followed by a list of PoC entities. The following options are
supported for Quartus:

+--------------------------+---------------------------------------------------------+
| Simulator Option         | Description                                             |
+====+=====================+=========================================================+
|    | --board=<BOARD>     | Specify a target board.                                 |
+----+---------------------+---------------------------------------------------------+
|    | --device=<DEVICE>   | Specify a target device.                                |
+----+---------------------+---------------------------------------------------------+

.. rubric:: Example:

.. code-block:: PowerShell

   cd <PoCRoot>
   .\poc.ps1 quartus PoC.arith.prng --board=DE4


Xilinx ISE Core Generator
=========================

The command to invoke a synthesis using Altera Quartus II or Quartus Prime is
``quartus`` followed by a list of PoC entities. The following options are
supported for Quartus:

+--------------------------+---------------------------------------------------------+
| Simulator Option         | Description                                             |
+====+=====================+=========================================================+
|    | --board=<BOARD>     | Specify a target board.                                 |
+----+---------------------+---------------------------------------------------------+
|    | --device=<DEVICE>   | Specify a target device.                                |
+----+---------------------+---------------------------------------------------------+

.. rubric:: Example:

.. code-block:: PowerShell

   cd <PoCRoot>
   .\poc.ps1 quartus PoC.arith.prng --board=DE4

Xilinx Vivado Synthesis
=======================

The command to invoke a synthesis using Altera Quartus II or Quartus Prime is
``quartus`` followed by a list of PoC entities. The following options are
supported for Quartus:

+--------------------------+---------------------------------------------------------+
| Simulator Option         | Description                                             |
+====+=====================+=========================================================+
|    | --board=<BOARD>     | Specify a target board.                                 |
+----+---------------------+---------------------------------------------------------+
|    | --device=<DEVICE>   | Specify a target device.                                |
+----+---------------------+---------------------------------------------------------+

.. rubric:: Example:

.. code-block:: PowerShell

   cd <PoCRoot>
   .\poc.ps1 quartus PoC.arith.prng --board=DE4



















Generated Netlists from PoC and IP Core Generators
**************************************************

The PoC-Library supports the generation of netlists from pre-configured
vendor IP cores (e.g. Xilinx Core Generator) or from bundled and pre-configured
PoC entities. This can be done by invoking PoC's Service Tool through the wrapper
script: `poc.[sh|ps1]`.

1 Common Explanations
*********************

A netlist is always compiled for a specific platform. In case of an FPGA it's
the exact device name. The name can be passed by `--device=<DEVICE>` command
line option to the script. An alternative is the `--board=<BOARD>` option. For
a list of well-known board names, PoC knows the soldered FPGA device.


2 Compiling pre-configured Xilinx IP Cores (*.xco files) to Netlists
**********************************************************************

**The PoC-Library** is shipped with some pre-configured IP cores from Xilinx.
These IP cores are shipped as \*.xco files and need to be compiled to netlists
(\*.ngc files) and there auxillary files (\*.ncf files; \*.vhdl files; ...). IP
core configuration files (e.g. *.xco) are stored as regular source files in the
`<PoCRoot>\src` directory.

```PowerShell
.\poc.ps1 [-q] [-v] [-d] coregen <PoC-Entity> [--device=<DEVICE>|--board=<BOARD>]
```

Use Case - Compiling all ChipScopeICON IP Cores
===============================================

PoC has an abstraction layer [`PoC.xil.ChipScopeICON`][xil_ChipScopeICON] to
abstract all possible Chipscope Integrated Controller (ICON) cores
configurations in one VHDL module. An ICON can be configured with 1 to 15
ChipScope control ports. To use the abstraction layer it's required to
pre-compile all 15 IP core variations.

The following example compiles the first IP core with 1 port for a Kintex-7
325T as soldered onto a KC705 board. The resulting netlist and auxillary files
are copied to `<PoCRoot>/netlist/XC7K325T-2FFG900/xil/`. The Xilinx ISE tool
flow requires an extension IP core search directory for *XST* and *Translate*
(`-sd` option).

```PowerShell
cd <PoCRoot>
.\poc.ps1 coregen PoC.xil.ChipScopeICON_1 --board=KC705
```

The compilation can be automated in a for-each loop for all IP cores:

```PowerShell
cd <PoCRoot>
foreach ($i in 1..15)
{	.\poc.ps1 coregen PoC.xil.ChipScopeICON_$_ --board=KC705
}
```


Compiling pre-configured PoC IP Cores (bundle of VHDL files) to Netlists
**************************************************************************

*Documentation is still incomplete*

The IP core filelist file (*.files) and the XST option file (*.xst) are stored
in the `<PoCRoot>\xst` directory.

```PowerShell
.\poc.ps1 [-q] [-v] [-d] xst <PoC-Entity> [--device=<DEVICE>|--board=<BOARD>]
```

Use Case - Compiling a Gigabit Ethernet UDP/IP Stack for a KC705 board
======================================================================

`PoC.net.stack.UDPv4`

*Documentation is still incomplete*

The resulting netlist and auxillary files
are copied to `<PoCRoot>/netlist/XC7K325T-2FFG900/net/stack`. The Xilinx ISE tool
flow requires an extension IP core search directory for *XST* and *Translate*
(`-sd` option).

 [xil_ChipScopeICON]:		../src/xil/xil_ChipScopeICON.vhdl