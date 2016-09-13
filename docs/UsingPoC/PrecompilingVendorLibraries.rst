
Pre-Compiling Vendor Libraries
##############################

.. contents:: Contents of this Page
   :local:


Overview
********

Running vendor specific testbenches may require pre-compiled vendor libraries.
Some vendors ship their simulators with diverse pre-compiled libraries, but these
don't include primitive libraries from hardware vendors. More over, many auxillary
libraries are outdated. Hardware vendors ship their tool chains with pre-compile
scripts or user guides to pre-compile the primitive libraries for a list of
supported simulators on a target system.

PoC is shipped with a set of pre-compile scripts to offer a unified interface
and common storage for all supported vendor's pre-compile procedures. The scripts
are located in ``\tools\precompile\`` and the output is stored in
``\temp\precompiled\<Simulator>\<Library>``.


Supported Simulators
********************

The current set of pre-compile scripts support these simulators:

+------------+------------------------------+--------------+--------------+---------------+--------------------+
| Vendor     | Simulator and Edition        | Altera       | Lattice      | Xilinx (ISE)  | Xilinx (Vivado)    |
+============+==============================+==============+==============+===============+====================+
| T. Gingold | GHDL with ``--std=93c`` |br| | yes |br|     | yes |br|     | yes |br|      | yes |br|           |
|            | GHDL with ``--std=08``       | yes          | yes          | yes           | yes                |
+------------+------------------------------+--------------+--------------+---------------+--------------------+
| Aldec      | Active-HDL |br|              | planned |br| | planned |br| | planned |br|  | planned |br|       |
|            | Active-HDL Lattice Ed. |br|  | planned |br| | shipped |br| | planned |br|  | planned |br|       |
|            | Reviera-PRO                  | planned      | planned      | planned       | planned            |
+------------+------------------------------+--------------+--------------+---------------+--------------------+
| Mentor     | ModelSim |br|                | yes |br|     | yes |br|     | yes |br|      | yes |br|           |
|            | ModelSim Altera Ed. |br|     | shipped |br| | yes |br|     | yes |br|      | yes |br|           |
|            | QuestaSim                    | yes          | yes          | yes           | yes                |
+------------+------------------------------+--------------+--------------+---------------+--------------------+
| Xilinx     | ISE Simulator |br|           |              |              | shipped |br|  | not supported |br| |
|            | Vivado Simulator             |              |              | not supported | shipped            |
+------------+------------------------------+--------------+--------------+---------------+--------------------+


FPGA Vendor's Primitive Libraries
*********************************

Altera
======

.. note::
   The Altera Quartus tool chain needs to be configured in PoC. |br|
   See :doc:`Configuring PoC's Infrastruture </UsingPoC/PoCConfiguration>` for further details.

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-altera.sh --all
   # Example 2 - Compile only for GHDL and VHDL-2008
   ./tools/precompile/compile-altera.sh --ghdl --vhdl2008

**List of command line arguments:**

+------------------+-------------------------------+
| Common Option    | Description                   |
+=====+============+===============================+
| -h  | --help     | Print embedded help page(s)   |
+-----+------------+-------------------------------+
| -c  | --clean    | Clean-up directories          |
+-----+------------+-------------------------------+
| -a  | --all      | Compile for all simulators    |
+-----+------------+-------------------------------+
|     | --ghdl     | Compile for GHDL              |
+-----+------------+-------------------------------+
|     | --questa   | Compile for QuestaSim         |
+-----+------------+-------------------------------+
|     | --vhdl93   | Compile only for VHDL-93      |
+-----+------------+-------------------------------+
|     | --vhdl2008 | Compile only for VHDL-2008    |
+-----+------------+-------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-altera.ps1 -All
   # Example 2 - Compile only for GHDL and VHDL-2008
   .\tools\precompile\compile-altera.ps1 -GHDL -VHDL2008

**List of command line arguments:**

+-----------------+-------------------------------+
| Common Option   | Description                   |
+=====+===========+===============================+
| -h  | -Help     | Print embedded help page(s)   |
+-----+-----------+-------------------------------+
| -c  | -Clean    | Clean-up directories          |
+-----+-----------+-------------------------------+
| -a  | -All      | Compile for all simulators    |
+-----+-----------+-------------------------------+
|     | -GHDL     | Compile for GHDL              |
+-----+-----------+-------------------------------+
|     | -Questa   | Compile for QuestaSim         |
+-----+-----------+-------------------------------+
|     | -VHDL93   | Compile only for VHDL-93      |
+-----+-----------+-------------------------------+
|     | -VHDL2008 | Compile only for VHDL-2008    |
+-----+-----------+-------------------------------+


Lattice
========

.. note::
   The Lattice Diamond tool chain needs to be configured in PoC. |br|
   See :doc:`Configuring PoC's Infrastruture </UsingPoC/PoCConfiguration>` for further details.

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-lattice.sh --all
   # Example 2 - Compile only for GHDL and VHDL-2008
   ./tools/precompile/compile-lattice.sh --ghdl --vhdl2008

**List of command line arguments:**

+------------------+-------------------------------+
| Common Option    | Description                   |
+=====+============+===============================+
| -h  | --help     | Print embedded help page(s)   |
+-----+------------+-------------------------------+
| -c  | --clean    | Clean-up directories          |
+-----+------------+-------------------------------+
| -a  | --all      | Compile for all simulators    |
+-----+------------+-------------------------------+
|     | --ghdl     | Compile for GHDL              |
+-----+------------+-------------------------------+
|     | --questa   | Compile for QuestaSim         |
+-----+------------+-------------------------------+
|     | --vhdl93   | Compile only for VHDL-93      |
+-----+------------+-------------------------------+
|     | --vhdl2008 | Compile only for VHDL-2008    |
+-----+------------+-------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-lattice.ps1 -All
   # Example 2 - Compile only for GHDL and VHDL-2008
   .\tools\precompile\compile-lattice.ps1 -GHDL -VHDL2008

**List of command line arguments:**

+-----------------+-------------------------------+
| Common Option   | Description                   |
+=====+===========+===============================+
| -h  | -Help     | Print embedded help page(s)   |
+-----+-----------+-------------------------------+
| -c  | -Clean    | Clean-up directories          |
+-----+-----------+-------------------------------+
| -a  | -All      | Compile for all simulators    |
+-----+-----------+-------------------------------+
|     | -GHDL     | Compile for GHDL              |
+-----+-----------+-------------------------------+
|     | -Questa   | Compile for QuestaSim         |
+-----+-----------+-------------------------------+
|     | -VHDL93   | Compile only for VHDL-93      |
+-----+-----------+-------------------------------+
|     | -VHDL2008 | Compile only for VHDL-2008    |
+-----+-----------+-------------------------------+

Xilinx ISE
==========

.. note::
   The Xilinx ISE tool chain needs to be configured in PoC. |br|
   See :doc:`Configuring PoC's Infrastruture </UsingPoC/PoCConfiguration>` for further details.

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-xilinx-ise.sh --all
   # Example 2 - Compile only for GHDL and VHDL-2008
   ./tools/precompile/compile-xilinx-ise.sh --ghdl --vhdl2008

**List of command line arguments:**

+------------------+-------------------------------+
| Common Option    | Description                   |
+=====+============+===============================+
| -h  | --help     | Print embedded help page(s)   |
+-----+------------+-------------------------------+
| -c  | --clean    | Clean-up directories          |
+-----+------------+-------------------------------+
| -a  | --all      | Compile for all simulators    |
+-----+------------+-------------------------------+
|     | --ghdl     | Compile for GHDL              |
+-----+------------+-------------------------------+
|     | --questa   | Compile for QuestaSim         |
+-----+------------+-------------------------------+
|     | --vhdl93   | Compile only for VHDL-93      |
+-----+------------+-------------------------------+
|     | --vhdl2008 | Compile only for VHDL-2008    |
+-----+------------+-------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-xilinx-ise.ps1 -All
   # Example 2 - Compile only for GHDL and VHDL-2008
   .\tools\precompile\compile-xilinx-ise.ps1 -GHDL -VHDL2008

**List of command line arguments:**

+-----------------+-------------------------------+
| Common Option   | Description                   |
+=====+===========+===============================+
| -h  | -Help     | Print embedded help page(s)   |
+-----+-----------+-------------------------------+
| -c  | -Clean    | Clean-up directories          |
+-----+-----------+-------------------------------+
| -a  | -All      | Compile for all simulators    |
+-----+-----------+-------------------------------+
|     | -GHDL     | Compile for GHDL              |
+-----+-----------+-------------------------------+
|     | -Questa   | Compile for QuestaSim         |
+-----+-----------+-------------------------------+
|     | -VHDL93   | Compile only for VHDL-93      |
+-----+-----------+-------------------------------+
|     | -VHDL2008 | Compile only for VHDL-2008    |
+-----+-----------+-------------------------------+

Xilinx Vivado
=============

.. note::
   The Xilinx Vivado tool chain needs to be configured in PoC. |br|
   See :doc:`Configuring PoC's Infrastruture </UsingPoC/PoCConfiguration>` for further details.

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-xilinx-vivado.sh --all
   # Example 2 - Compile only for GHDL and VHDL-2008
   ./tools/precompile/compile-xilinx-vivado.sh --ghdl --vhdl2008

**List of command line arguments:**

+------------------+-------------------------------+
| Common Option    | Description                   |
+=====+============+===============================+
| -h  | --help     | Print embedded help page(s)   |
+-----+------------+-------------------------------+
| -c  | --clean    | Clean-up directories          |
+-----+------------+-------------------------------+
| -a  | --all      | Compile for all simulators    |
+-----+------------+-------------------------------+
|     | --ghdl     | Compile for GHDL              |
+-----+------------+-------------------------------+
|     | --questa   | Compile for QuestaSim         |
+-----+------------+-------------------------------+
|     | --vhdl93   | Compile only for VHDL-93      |
+-----+------------+-------------------------------+
|     | --vhdl2008 | Compile only for VHDL-2008    |
+-----+------------+-------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-xilinx-vivado.ps1 -All
   # Example 2 - Compile only for GHDL and VHDL-2008
   .\tools\precompile\compile-xilinx-vivado.ps1 -GHDL -VHDL2008

**List of command line arguments:**

+-----------------+-------------------------------+
| Common Option   | Description                   |
+=====+===========+===============================+
| -h  | -Help     | Print embedded help page(s)   |
+-----+-----------+-------------------------------+
| -c  | -Clean    | Clean-up directories          |
+-----+-----------+-------------------------------+
| -a  | -All      | Compile for all simulators    |
+-----+-----------+-------------------------------+
|     | -GHDL     | Compile for GHDL              |
+-----+-----------+-------------------------------+
|     | -Questa   | Compile for QuestaSim         |
+-----+-----------+-------------------------------+
|     | -VHDL93   | Compile only for VHDL-93      |
+-----+-----------+-------------------------------+
|     | -VHDL2008 | Compile only for VHDL-2008    |
+-----+-----------+-------------------------------+

Third-Party Libraries
*********************

OSVVM
=====

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-osvvm.sh --all
   # Example 2 - Compile only for GHDL
   ./tools/precompile/compile-osvvm.sh --ghdl

**List of command line arguments:**

+------------------+-------------------------------+
| Common Option    | Description                   |
+=====+============+===============================+
| -h  | --help     | Print embedded help page(s)   |
+-----+------------+-------------------------------+
| -c  | --clean    | Clean-up directories          |
+-----+------------+-------------------------------+
| -a  | --all      | Compile for all simulators    |
+-----+------------+-------------------------------+
|     | --ghdl     | Compile for GHDL              |
+-----+------------+-------------------------------+
|     | --questa   | Compile for QuestaSim         |
+-----+------------+-------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-osvvm.ps1 -All
   # Example 2 - Compile only for GHDL
   .\tools\precompile\compile-osvvm.ps1 -GHDL

**List of command line arguments:**

+-----------------+-------------------------------+
| Common Option   | Description                   |
+=====+===========+===============================+
| -h  | -Help     | Print embedded help page(s)   |
+-----+-----------+-------------------------------+
| -c  | -Clean    | Clean-up directories          |
+-----+-----------+-------------------------------+
| -a  | -All      | Compile for all simulators    |
+-----+-----------+-------------------------------+
|     | -GHDL     | Compile for GHDL              |
+-----+-----------+-------------------------------+
|     | -Questa   | Compile for QuestaSim         |
+-----+-----------+-------------------------------+


Simulator Adapters
******************

Cocotb
======


On Linux
--------

.. attention::
   This is an experimental compile script.

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-cocotb.sh --all
   # Example 2 - Compile only for GHDL
   ./tools/precompile/compile-cocotb.sh --ghdl

**List of command line arguments:**

+------------------+-------------------------------+
| Common Option    | Description                   |
+=====+============+===============================+
| -h  | --help     | Print embedded help page(s)   |
+-----+------------+-------------------------------+
| -c  | --clean    | Clean-up directories          |
+-----+------------+-------------------------------+
| -a  | --all      | Compile for all simulators    |
+-----+------------+-------------------------------+
|     | --ghdl     | Compile for GHDL              |
+-----+------------+-------------------------------+
|     | --questa   | Compile for QuestaSim         |
+-----+------------+-------------------------------+


On Windows
----------

.. attention::
   This is an experimental compile script.

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-cocotb.ps1 -All
   # Example 2 - Compile only for GHDL
   .\tools\precompile\compile-cocotb.ps1 -GHDL

**List of command line arguments:**

+-----------------+-------------------------------+
| Common Option   | Description                   |
+=====+===========+===============================+
| -h  | -Help     | Print embedded help page(s)   |
+-----+-----------+-------------------------------+
| -c  | -Clean    | Clean-up directories          |
+-----+-----------+-------------------------------+
| -a  | -All      | Compile for all simulators    |
+-----+-----------+-------------------------------+
|     | -GHDL     | Compile for GHDL              |
+-----+-----------+-------------------------------+
|     | -Questa   | Compile for QuestaSim         |
+-----+-----------+-------------------------------+

.. comment

   Supported Simulators:

   +--------------------------------+------------------------------------------------------------------------------+
   | Simulator Name                 | Comment                                                                      |
   +================================+==============================================================================+
   | GHDL                           | VHDL-93 version is compiled with ``--std=93c`` and ``--ieee=synopsys``. |br| |
   |                                | VHDL-2008 version is compiled with ``--std=08`` and ``--ieee=synopsys``.     |
   +--------------------------------+------------------------------------------------------------------------------+
   | Mentor ModelSim Altera Edition | Already includes all Altera primitives.                                      |
   +--------------------------------+------------------------------------------------------------------------------+
   | Mentor QuestaSim               |                                                                              |
   +--------------------------------+------------------------------------------------------------------------------+

   +---------------------------------------------------+--------------------------------------------+
   | Compile Script Location (Bash)                    | Output Directory                           |
   +===================================================+============================================+
   | ``<PoCRoot>/tools/precompile/compile-altera.sh``  | ``<PoCRoot>/temp/precompiled/vsim/altera`` |
   +---------------------------------------------------+--------------------------------------------+

   +---------------------------------------------------+--------------------------------------------+
   | Compile Script Location (PowerShell)              | Output Directory                           |
   +===================================================+============================================+
   | ``<PoCRoot>\tools\precompile\compile-altera.ps1`` | ``<PoCRoot>\temp\precompiled\vsim\altera`` |
   +---------------------------------------------------+--------------------------------------------+

