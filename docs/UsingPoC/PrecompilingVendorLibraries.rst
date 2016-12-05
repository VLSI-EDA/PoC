.. _USING:PreCompile:

Pre-Compiling Vendor Libraries
##############################

.. contents:: Contents of this Page
   :local:
   :depth: 2
   :backlinks: entry


.. index::
   single: Pre-compilation

.. _USING:PreCompile:Over:

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


.. index::
   pair: Pre-compilation; Supported Simulators

.. _USING:PreCompile:Simulators:

Supported Simulators
********************

The current set of pre-compile scripts support these simulators:

+------------------+--------------------------------------+--------------+--------------+-----------------+----------------------+
| Vendor           | Simulator and Edition                | Altera       | Lattice      | Xilinx (ISE)    | Xilinx (Vivado)      |
+==================+======================================+==============+==============+=================+======================+
| T. Gingold |br|  | GHDL with ``--std=93c`` |br|         | yes |br|     | yes |br|     | yes |br|        | yes |br|             |
|                  | GHDL with ``--std=08``               | yes          | yes          | yes             | yes                  |
+------------------+--------------------------------------+--------------+--------------+-----------------+----------------------+
| Aldec |br|       | Active-HDL (or Stududent Ed.) |br|   | planned |br| | planned |br| | planned |br|    | planned |br|         |
| |br|             | Active-HDL Lattice Ed. |br|          | planned |br| | shipped |br| | planned |br|    | planned |br|         |
|                  | Reviera-PRO                          | planned      | planned      | planned         | planned              |
+------------------+--------------------------------------+--------------+--------------+-----------------+----------------------+
| Mentor |br|      | ModelSim PE (or Stududent Ed.) |br|  | yes |br|     | yes |br|     | yes |br|        | yes |br|             |
| |br|             | ModelSim SE |br|                     | yes |br|     | yes |br|     | yes |br|        | yes |br|             |
| |br|             | ModelSim Altera Ed. |br|             | shipped |br| | yes |br|     | yes |br|        | yes |br|             |
|                  | QuestaSim                            | yes          | yes          | yes             | yes                  |
+------------------+--------------------------------------+--------------+--------------+-----------------+----------------------+
| Xilinx |br|      | ISE Simulator |br|                   |              |              | shipped |br|    | not supported |br|   |
|                  | Vivado Simulator                     |              |              | not supported   | shipped              |
+------------------+--------------------------------------+--------------+--------------+-----------------+----------------------+


.. index::
   pair: Pre-compilation; Vendor Primitives

.. _USING:PreCompile:Primitives:

FPGA Vendor's Primitive Libraries
****************************************************************************************************************************************************************

.. # ===========================================================================================================================================================
.. index::
   pair: Pre-compilation; Altera

.. _USING:PreCompile:Primitives:Altera:

Altera
======

.. note::
   The Altera Quartus tool chain needs to be configured in PoC. |br|
   See :ref:`Configuring PoC's Infrastruture <USING:PoCConfig>` for further details.

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-altera.sh --all
   # Example 2 - Compile only for GHDL and VHDL-2008
   ./tools/precompile/compile-altera.sh --ghdl --vhdl2008

**List of command line arguments:**

.. |c-altera-sh-h| replace:: :option:`-h <compile-altera.sh -h>`
.. |c-altera-sh-c| replace:: :option:`-c <compile-altera.sh -c>`
.. |c-altera-sh-a| replace:: :option:`-a <compile-altera.sh -a>`
.. |c-altera-sh-help| replace:: :option:`--help <compile-altera.sh --help>`
.. |c-altera-sh-clean| replace:: :option:`--clean <compile-altera.sh --clean>`
.. |c-altera-sh-all| replace:: :option:`--all <compile-altera.sh --all>`
.. |c-altera-sh-ghdl| replace:: :option:`--ghdl <compile-altera.sh --ghdl>`
.. |c-altera-sh-questa| replace:: :option:`--questa <compile-altera.sh --questa>`
.. |c-altera-sh-vhdl93| replace:: :option:`--vhdl93 <compile-altera.sh --vhdl93>`
.. |c-altera-sh-vhdl08| replace:: :option:`--vhdl2008 <compile-altera.sh --vhdl2008>`

+------------------------------------------+---------------------------------------------------------------------------+
| Common Option                            | Parameter Description                                                     |
+==================+=======================+===========================================================================+
| |c-altera-sh-h|  | |c-altera-sh-help|    | Print embedded help page(s).                                              |
+------------------+-----------------------+---------------------------------------------------------------------------+
| |c-altera-sh-c|  | |c-altera-sh-clean|   | Clean-up directories.                                                     |
+------------------+-----------------------+---------------------------------------------------------------------------+
| |c-altera-sh-a|  | |c-altera-sh-all|     | Compile for all simulators.                                               |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-altera-sh-ghdl|    | Compile for GHDL.                                                         |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-altera-sh-questa|  | Compile for QuestaSim.                                                    |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-altera-sh-vhdl93|  | GHDL only: Compile only for VHDL-93.                                      |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-altera-sh-vhdl08|  | GHDL only: Compile only for VHDL-2008.                                    |
+------------------+-----------------------+---------------------------------------------------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-altera.ps1 -All
   # Example 2 - Compile only for GHDL and VHDL-2008
   .\tools\precompile\compile-altera.ps1 -GHDL -VHDL2008

**List of command line arguments:**

.. |c-altera-ps-h| replace:: ``-h``
.. |c-altera-ps-c| replace:: ``-c``
.. |c-altera-ps-a| replace:: ``-a``
.. |c-altera-ps-help| replace:: :option:`-Help <compile-altera.ps1 -Help>`
.. |c-altera-ps-clean| replace:: :option:`-Clean <compile-altera.ps1 -Clean>`
.. |c-altera-ps-all| replace:: :option:`-All <compile-altera.ps1 -All>`
.. |c-altera-ps-ghdl| replace:: :option:`-GHDL <compile-altera.ps1 -GHDL>`
.. |c-altera-ps-questa| replace:: :option:`-Questa <compile-altera.ps1 -Questa>`
.. |c-altera-ps-vhdl93| replace:: :option:`-VHDL93 <compile-altera.ps1 -VHDL93>`
.. |c-altera-ps-vhdl08| replace:: :option:`-VHDL2008 <compile-altera.ps1 -VHDL2008>`

+------------------------------------------+---------------------------------------------------------------------------+
| Common Option                            | Parameter Description                                                     |
+==================+=======================+===========================================================================+
| |c-altera-ps-h|  | |c-altera-ps-help|    | Print embedded help page(s).                                              |
+------------------+-----------------------+---------------------------------------------------------------------------+
| |c-altera-ps-c|  | |c-altera-ps-clean|   | Clean-up directories.                                                     |
+------------------+-----------------------+---------------------------------------------------------------------------+
| |c-altera-ps-a|  | |c-altera-ps-all|     | Compile for all simulators.                                               |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-altera-ps-ghdl|    | Compile for GHDL.                                                         |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-altera-ps-questa|  | Compile for QuestaSim.                                                    |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-altera-ps-vhdl93|  | GHDL only: Compile only for VHDL-93.                                      |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-altera-ps-vhdl08|  | GHDL only: Compile only for VHDL-2008.                                    |
+------------------+-----------------------+---------------------------------------------------------------------------+

.. # ===========================================================================================================================================================
.. index::
   pair: Pre-compilation; Lattice

.. _USING:PreCompile:Primitives:Lattice:

Lattice
========

.. note::
   The Lattice Diamond tool chain needs to be configured in PoC. |br|
   See :ref:`Configuring PoC's Infrastruture <USING:PoCConfig>` for further details.

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-lattice.sh --all
   # Example 2 - Compile only for GHDL and VHDL-2008
   ./tools/precompile/compile-lattice.sh --ghdl --vhdl2008

**List of command line arguments:**

.. |c-lattice-sh-h| replace:: :option:`-h <compile-lattice.sh -h>`
.. |c-lattice-sh-c| replace:: :option:`-c <compile-lattice.sh -c>`
.. |c-lattice-sh-a| replace:: :option:`-a <compile-lattice.sh -a>`
.. |c-lattice-sh-help| replace:: :option:`--help <compile-lattice.sh --help>`
.. |c-lattice-sh-clean| replace:: :option:`--clean <compile-lattice.sh --clean>`
.. |c-lattice-sh-all| replace:: :option:`--all <compile-lattice.sh --all>`
.. |c-lattice-sh-ghdl| replace:: :option:`--ghdl <compile-lattice.sh --ghdl>`
.. |c-lattice-sh-questa| replace:: :option:`--questa <compile-lattice.sh --questa>`
.. |c-lattice-sh-vhdl93| replace:: :option:`--vhdl93 <compile-lattice.sh --vhdl93>`
.. |c-lattice-sh-vhdl08| replace:: :option:`--vhdl2008 <compile-lattice.sh --vhdl2008>`

+--------------------------------------------+-------------------------------------------------------------------------+
| Common Option                              | Parameter Description                                                   |
+===================+========================+=========================================================================+
| |c-lattice-sh-h|  | |c-lattice-sh-help|    | Print embedded help page(s).                                            |
+-------------------+------------------------+-------------------------------------------------------------------------+
| |c-lattice-sh-c|  | |c-lattice-sh-clean|   | Clean-up directories.                                                   |
+-------------------+------------------------+-------------------------------------------------------------------------+
| |c-lattice-sh-a|  | |c-lattice-sh-all|     | Compile for all simulators.                                             |
+-------------------+------------------------+-------------------------------------------------------------------------+
|                   | |c-lattice-sh-ghdl|    | Compile for GHDL.                                                       |
+-------------------+------------------------+-------------------------------------------------------------------------+
|                   | |c-lattice-sh-questa|  | Compile for QuestaSim.                                                  |
+-------------------+------------------------+-------------------------------------------------------------------------+
|                   | |c-lattice-sh-vhdl93|  | GHDL only: Compile only for VHDL-93.                                    |
+-------------------+------------------------+-------------------------------------------------------------------------+
|                   | |c-lattice-sh-vhdl08|  | GHDL only: Compile only for VHDL-2008.                                  |
+-------------------+------------------------+-------------------------------------------------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-lattice.ps1 -All
   # Example 2 - Compile only for GHDL and VHDL-2008
   .\tools\precompile\compile-lattice.ps1 -GHDL -VHDL2008

**List of command line arguments:**

.. |c-lattice-ps-h| replace:: ``-h``
.. |c-lattice-ps-c| replace:: ``-c``
.. |c-lattice-ps-a| replace:: ``-a``
.. |c-lattice-ps-help| replace:: :option:`-Help <compile-lattice.ps1 -Help>`
.. |c-lattice-ps-clean| replace:: :option:`-Clean <compile-lattice.ps1 -Clean>`
.. |c-lattice-ps-all| replace:: :option:`-All <compile-lattice.ps1 -All>`
.. |c-lattice-ps-ghdl| replace:: :option:`-GHDL <compile-lattice.ps1 -GHDL>`
.. |c-lattice-ps-questa| replace:: :option:`-Questa <compile-lattice.ps1 -Questa>`
.. |c-lattice-ps-vhdl93| replace:: :option:`-VHDL93 <compile-lattice.ps1 -VHDL93>`
.. |c-lattice-ps-vhdl08| replace:: :option:`-VHDL2008 <compile-lattice.ps1 -VHDL2008>`

+--------------------------------------------+-------------------------------------------------------------------------+
| Common Option                              | Parameter Description                                                   |
+===================+========================+=========================================================================+
| |c-lattice-ps-h|  | |c-lattice-ps-help|    | Print embedded help page(s).                                            |
+-------------------+------------------------+-------------------------------------------------------------------------+
| |c-lattice-ps-c|  | |c-lattice-ps-clean|   | Clean-up directories.                                                   |
+-------------------+------------------------+-------------------------------------------------------------------------+
| |c-lattice-ps-a|  | |c-lattice-ps-all|     | Compile for all simulators.                                             |
+-------------------+------------------------+-------------------------------------------------------------------------+
|                   | |c-lattice-ps-ghdl|    | Compile for GHDL.                                                       |
+-------------------+------------------------+-------------------------------------------------------------------------+
|                   | |c-lattice-ps-questa|  | Compile for QuestaSim.                                                  |
+-------------------+------------------------+-------------------------------------------------------------------------+
|                   | |c-lattice-ps-vhdl93|  | GHDL only: Compile only for VHDL-93.                                    |
+-------------------+------------------------+-------------------------------------------------------------------------+
|                   | |c-lattice-ps-vhdl08|  | GHDL only: Compile only for VHDL-2008.                                  |
+-------------------+------------------------+-------------------------------------------------------------------------+

.. # ===========================================================================================================================================================
.. index::
   pair: Pre-compilation; Xilinx ISE

.. _USING:PreCompile:Primitives:XilinxISE:

Xilinx ISE
==========

.. note::
   The Xilinx ISE tool chain needs to be configured in PoC. |br|
   See :ref:`Configuring PoC's Infrastruture <USING:PoCConfig>` for further details.

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-xilinx-ise.sh --all
   # Example 2 - Compile only for GHDL and VHDL-2008
   ./tools/precompile/compile-xilinx-ise.sh --ghdl --vhdl2008

**List of command line arguments:**

.. |c-ise-sh-h| replace:: :option:`-h <compile-xilinx-ise.sh -h>`
.. |c-ise-sh-c| replace:: :option:`-c <compile-xilinx-ise.sh -c>`
.. |c-ise-sh-a| replace:: :option:`-a <compile-xilinx-ise.sh -a>`
.. |c-ise-sh-help| replace:: :option:`--help <compile-xilinx-ise.sh --help>`
.. |c-ise-sh-clean| replace:: :option:`--clean <compile-xilinx-ise.sh --clean>`
.. |c-ise-sh-all| replace:: :option:`--all <compile-xilinx-ise.sh --all>`
.. |c-ise-sh-ghdl| replace:: :option:`--ghdl <compile-xilinx-ise.sh --ghdl>`
.. |c-ise-sh-questa| replace:: :option:`--questa <compile-xilinx-ise.sh --questa>`
.. |c-ise-sh-vhdl93| replace:: :option:`--vhdl93 <compile-xilinx-ise.sh --vhdl93>`
.. |c-ise-sh-vhdl08| replace:: :option:`--vhdl2008 <compile-xilinx-ise.sh --vhdl2008>`

+------------------------------------+---------------------------------------------------------------------------------+
| Common Option                      | Parameter Description                                                           |
+===============+====================+=================================================================================+
| |c-ise-sh-h|  | |c-ise-sh-help|    | Print embedded help page(s).                                                    |
+---------------+--------------------+---------------------------------------------------------------------------------+
| |c-ise-sh-c|  | |c-ise-sh-clean|   | Clean-up directories.                                                           |
+---------------+--------------------+---------------------------------------------------------------------------------+
| |c-ise-sh-a|  | |c-ise-sh-all|     | Compile for all simulators.                                                     |
+---------------+--------------------+---------------------------------------------------------------------------------+
|               | |c-ise-sh-ghdl|    | Compile for GHDL.                                                               |
+---------------+--------------------+---------------------------------------------------------------------------------+
|               | |c-ise-sh-questa|  | Compile for QuestaSim.                                                          |
+---------------+--------------------+---------------------------------------------------------------------------------+
|               | |c-ise-sh-vhdl93|  | GHDL only: Compile only for VHDL-93.                                            |
+---------------+--------------------+---------------------------------------------------------------------------------+
|               | |c-ise-sh-vhdl08|  | GHDL only: Compile only for VHDL-2008.                                          |
+---------------+--------------------+---------------------------------------------------------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-xilinx-ise.ps1 -All
   # Example 2 - Compile only for GHDL and VHDL-2008
   .\tools\precompile\compile-xilinx-ise.ps1 -GHDL -VHDL2008

**List of command line arguments:**

.. |c-ise-ps-h| replace:: ``-h``
.. |c-ise-ps-c| replace:: ``-c``
.. |c-ise-ps-a| replace:: ``-a``
.. |c-ise-ps-help| replace:: :option:`-Help <compile-xilinx-ise.ps1 -Help>`
.. |c-ise-ps-clean| replace:: :option:`-Clean <compile-xilinx-ise.ps1 -Clean>`
.. |c-ise-ps-all| replace:: :option:`-All <compile-xilinx-ise.ps1 -All>`
.. |c-ise-ps-ghdl| replace:: :option:`-GHDL <compile-xilinx-ise.ps1 -GHDL>`
.. |c-ise-ps-questa| replace:: :option:`-Questa <compile-xilinx-ise.ps1 -Questa>`
.. |c-ise-ps-vhdl93| replace:: :option:`-VHDL93 <compile-xilinx-ise.ps1 -VHDL93>`
.. |c-ise-ps-vhdl08| replace:: :option:`-VHDL2008 <compile-xilinx-ise.ps1 -VHDL2008>`

+------------------------------------+---------------------------------------------------------------------------------+
| Common Option                      | Parameter Description                                                           |
+===============+====================+=================================================================================+
| |c-ise-ps-h|  | |c-ise-ps-help|    | Print embedded help page(s).                                                    |
+---------------+--------------------+---------------------------------------------------------------------------------+
| |c-ise-ps-c|  | |c-ise-ps-clean|   | Clean-up directories.                                                           |
+---------------+--------------------+---------------------------------------------------------------------------------+
| |c-ise-ps-a|  | |c-ise-ps-all|     | Compile for all simulators.                                                     |
+---------------+--------------------+---------------------------------------------------------------------------------+
|               | |c-ise-ps-ghdl|    | Compile for GHDL.                                                               |
+---------------+--------------------+---------------------------------------------------------------------------------+
|               | |c-ise-ps-questa|  | Compile for QuestaSim.                                                          |
+---------------+--------------------+---------------------------------------------------------------------------------+
|               | |c-ise-ps-vhdl93|  | GHDL only: Compile only for VHDL-93.                                            |
+---------------+--------------------+---------------------------------------------------------------------------------+
|               | |c-ise-ps-vhdl08|  | GHDL only: Compile only for VHDL-2008.                                          |
+---------------+--------------------+---------------------------------------------------------------------------------+

.. # ===========================================================================================================================================================
.. index::
   pair: Pre-compilation; Xilinx Vivado

.. _USING:PreCompile:Primitives:XilinxVivado

Xilinx Vivado
=============

.. note::
   The Xilinx Vivado tool chain needs to be configured in PoC. |br|
   See :ref:`Configuring PoC's Infrastruture <USING:PoCConfig>` for further details.

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-xilinx-vivado.sh --all
   # Example 2 - Compile only for GHDL and VHDL-2008
   ./tools/precompile/compile-xilinx-vivado.sh --ghdl --vhdl2008

**List of command line arguments:**

.. |c-vivado-sh-h| replace:: :option:`-h <compile-xilinx-vivado.sh -h>`
.. |c-vivado-sh-c| replace:: :option:`-c <compile-xilinx-vivado.sh -c>`
.. |c-vivado-sh-a| replace:: :option:`-a <compile-xilinx-vivado.sh -a>`
.. |c-vivado-sh-help| replace:: :option:`--help <compile-xilinx-vivado.sh --help>`
.. |c-vivado-sh-clean| replace:: :option:`--clean <compile-xilinx-vivado.sh --clean>`
.. |c-vivado-sh-all| replace:: :option:`--all <compile-xilinx-vivado.sh --all>`
.. |c-vivado-sh-ghdl| replace:: :option:`--ghdl <compile-xilinx-vivado.sh --ghdl>`
.. |c-vivado-sh-questa| replace:: :option:`--questa <compile-xilinx-vivado.sh --questa>`
.. |c-vivado-sh-vhdl93| replace:: :option:`--vhdl93 <compile-xilinx-vivado.sh --vhdl93>`
.. |c-vivado-sh-vhdl08| replace:: :option:`--vhdl2008 <compile-xilinx-vivado.sh --vhdl2008>`

+------------------------------------------+---------------------------------------------------------------------------+
| Common Option                            | Parameter Description                                                     |
+==================+=======================+===========================================================================+
| |c-vivado-sh-h|  | |c-vivado-sh-help|    | Print embedded help page(s).                                              |
+------------------+-----------------------+---------------------------------------------------------------------------+
| |c-vivado-sh-c|  | |c-vivado-sh-clean|   | Clean-up directories.                                                     |
+------------------+-----------------------+---------------------------------------------------------------------------+
| |c-vivado-sh-a|  | |c-vivado-sh-all|     | Compile for all simulators.                                               |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-vivado-sh-ghdl|    | Compile for GHDL.                                                         |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-vivado-sh-questa|  | Compile for QuestaSim.                                                    |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-vivado-sh-vhdl93|  | GHDL only: Compile only for VHDL-93.                                      |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-vivado-sh-vhdl08|  | GHDL only: Compile only for VHDL-2008.                                    |
+------------------+-----------------------+---------------------------------------------------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-xilinx-vivado.ps1 -All
   # Example 2 - Compile only for GHDL and VHDL-2008
   .\tools\precompile\compile-xilinx-vivado.ps1 -GHDL -VHDL2008

**List of command line arguments:**

.. |c-vivado-ps-h| replace:: ``-h``
.. |c-vivado-ps-c| replace:: ``-c``
.. |c-vivado-ps-a| replace:: ``-a``
.. |c-vivado-ps-help| replace:: :option:`-Help <compile-xilinx-vivado.ps1 -Help>`
.. |c-vivado-ps-clean| replace:: :option:`-Clean <compile-xilinx-vivado.ps1 -Clean>`
.. |c-vivado-ps-all| replace:: :option:`-All <compile-xilinx-vivado.ps1 -All>`
.. |c-vivado-ps-ghdl| replace:: :option:`-GHDL <compile-xilinx-vivado.ps1 -GHDL>`
.. |c-vivado-ps-questa| replace:: :option:`-Questa <compile-xilinx-vivado.ps1 -Questa>`
.. |c-vivado-ps-vhdl93| replace:: :option:`-VHDL93 <compile-xilinx-vivado.ps1 -VHDL93>`
.. |c-vivado-ps-vhdl08| replace:: :option:`-VHDL2008 <compile-xilinx-vivado.ps1 -VHDL2008>`

+------------------------------------------+---------------------------------------------------------------------------+
| Common Option                            | Parameter Description                                                     |
+==================+=======================+===========================================================================+
| |c-vivado-ps-h|  | |c-vivado-ps-help|    | Print embedded help page(s).                                              |
+------------------+-----------------------+---------------------------------------------------------------------------+
| |c-vivado-ps-c|  | |c-vivado-ps-clean|   | Clean-up directories.                                                     |
+------------------+-----------------------+---------------------------------------------------------------------------+
| |c-vivado-ps-a|  | |c-vivado-ps-all|     | Compile for all simulators.                                               |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-vivado-ps-ghdl|    | Compile for GHDL.                                                         |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-vivado-ps-questa|  | Compile for QuestaSim.                                                    |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-vivado-ps-vhdl93|  | GHDL only: Compile only for VHDL-93.                                      |
+------------------+-----------------------+---------------------------------------------------------------------------+
|                  | |c-vivado-ps-vhdl08|  | GHDL only: Compile only for VHDL-2008.                                    |
+------------------+-----------------------+---------------------------------------------------------------------------+

.. # ===========================================================================================================================================================
.. index::
   pair: Pre-compilation; Third-Party Libraries

.. _USING:PreCompile:ThirdParty:

Third-Party Libraries
****************************************************************************************************************************************************************

.. # ===========================================================================================================================================================
.. index::
   pair: Pre-compilation; OSVVM

.. _USING:PreCompile:ThirdParty:OSVVM:

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

.. |c-osvvm-sh-h| replace:: :option:`-h <compile-osvvm.sh -h>`
.. |c-osvvm-sh-c| replace:: :option:`-c <compile-osvvm.sh -c>`
.. |c-osvvm-sh-a| replace:: :option:`-a <compile-osvvm.sh -a>`
.. |c-osvvm-sh-help| replace:: :option:`--help <compile-osvvm.sh --help>`
.. |c-osvvm-sh-clean| replace:: :option:`--clean <compile-osvvm.sh --clean>`
.. |c-osvvm-sh-all| replace:: :option:`--all <compile-osvvm.sh --all>`
.. |c-osvvm-sh-ghdl| replace:: :option:`--ghdl <compile-osvvm.sh --ghdl>`
.. |c-osvvm-sh-questa| replace:: :option:`--questa <compile-osvvm.sh --questa>`

+----------------------------------------+-----------------------------------------------------------------------------+
| Common Option                          | Parameter Description                                                       |
+=================+======================+=============================================================================+
| |c-osvvm-sh-h|  | |c-osvvm-sh-help|    | Print embedded help page(s).                                                |
+-----------------+----------------------+-----------------------------------------------------------------------------+
| |c-osvvm-sh-c|  | |c-osvvm-sh-clean|   | Clean-up directories.                                                       |
+-----------------+----------------------+-----------------------------------------------------------------------------+
| |c-osvvm-sh-a|  | |c-osvvm-sh-all|     | Compile for all simulators.                                                 |
+-----------------+----------------------+-----------------------------------------------------------------------------+
|                 | |c-osvvm-sh-ghdl|    | Compile for GHDL.                                                           |
+-----------------+----------------------+-----------------------------------------------------------------------------+
|                 | |c-osvvm-sh-questa|  | Compile for QuestaSim.                                                      |
+-----------------+----------------------+-----------------------------------------------------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-osvvm.ps1 -All
   # Example 2 - Compile only for GHDL
   .\tools\precompile\compile-osvvm.ps1 -GHDL

**List of command line arguments:**

.. |c-osvvm-ps-h| replace:: ``-h``
.. |c-osvvm-ps-c| replace:: ``-c``
.. |c-osvvm-ps-a| replace:: ``-a``
.. |c-osvvm-ps-help| replace:: :option:`-Help <compile-osvvm.ps1 -Help>`
.. |c-osvvm-ps-clean| replace:: :option:`-Clean <compile-osvvm.ps1 -Clean>`
.. |c-osvvm-ps-all| replace:: :option:`-All <compile-osvvm.ps1 -All>`
.. |c-osvvm-ps-ghdl| replace:: :option:`-GHDL <compile-osvvm.ps1 -GHDL>`
.. |c-osvvm-ps-questa| replace:: :option:`-Questa <compile-osvvm.ps1 -Questa>`

+----------------------------------------+-----------------------------------------------------------------------------+
| Common Option                          | Parameter Description                                                       |
+=================+======================+=============================================================================+
| |c-osvvm-ps-h|  | |c-osvvm-ps-help|    | Print embedded help page(s).                                                |
+-----------------+----------------------+-----------------------------------------------------------------------------+
| |c-osvvm-ps-c|  | |c-osvvm-ps-clean|   | Clean-up directories.                                                       |
+-----------------+----------------------+-----------------------------------------------------------------------------+
| |c-osvvm-ps-a|  | |c-osvvm-ps-all|     | Compile for all simulators.                                                 |
+-----------------+----------------------+-----------------------------------------------------------------------------+
|                 | |c-osvvm-ps-ghdl|    | Compile for GHDL.                                                           |
+-----------------+----------------------+-----------------------------------------------------------------------------+
|                 | |c-osvvm-ps-questa|  | Compile for QuestaSim.                                                      |
+-----------------+----------------------+-----------------------------------------------------------------------------+

.. # ===========================================================================================================================================================
.. index::
   pair: Pre-compilation; UVVM

.. _USING:PreCompile:ThirdParty:UVVM:

UVVM
====

On Linux
--------

.. code-block:: Bash

   # Example 1 - Compile for all Simulators
   ./tools/precompile/compile-uvvm.sh --all
   # Example 2 - Compile only for GHDL
   ./tools/precompile/compile-uvvm.sh --ghdl

**List of command line arguments:**

.. |c-uvvm-sh-h| replace:: :option:`-h <compile-uvvm.sh -h>`
.. |c-uvvm-sh-c| replace:: :option:`-c <compile-uvvm.sh -c>`
.. |c-uvvm-sh-a| replace:: :option:`-a <compile-uvvm.sh -a>`
.. |c-uvvm-sh-help| replace:: :option:`--help <compile-uvvm.sh --help>`
.. |c-uvvm-sh-clean| replace:: :option:`--clean <compile-uvvm.sh --clean>`
.. |c-uvvm-sh-all| replace:: :option:`--all <compile-uvvm.sh --all>`
.. |c-uvvm-sh-ghdl| replace:: :option:`--ghdl <compile-uvvm.sh --ghdl>`
.. |c-uvvm-sh-questa| replace:: :option:`--questa <compile-uvvm.sh --questa>`

+--------------------------------------+-------------------------------------------------------------------------------+
| Common Option                        | Parameter Description                                                         |
+================+=====================+===============================================================================+
| |c-uvvm-sh-h|  | |c-uvvm-sh-help|    | Print embedded help page(s).                                                  |
+----------------+---------------------+-------------------------------------------------------------------------------+
| |c-uvvm-sh-c|  | |c-uvvm-sh-clean|   | Clean-up directories.                                                         |
+----------------+---------------------+-------------------------------------------------------------------------------+
| |c-uvvm-sh-a|  | |c-uvvm-sh-all|     | Compile for all simulators.                                                   |
+----------------+---------------------+-------------------------------------------------------------------------------+
|                | |c-uvvm-sh-ghdl|    | Compile for GHDL.                                                             |
+----------------+---------------------+-------------------------------------------------------------------------------+
|                | |c-uvvm-sh-questa|  | Compile for QuestaSim.                                                        |
+----------------+---------------------+-------------------------------------------------------------------------------+


On Windows
----------

.. code-block:: PowerShell

   # Example 1 - Compile for all Simulators
   .\tools\precompile\compile-uvvm.ps1 -All
   # Example 2 - Compile only for GHDL
   .\tools\precompile\compile-uvvm.ps1 -GHDL

**List of command line arguments:**

.. |c-uvvm-ps-h| replace:: ``-h``
.. |c-uvvm-ps-c| replace:: ``-c``
.. |c-uvvm-ps-a| replace:: ``-a``
.. |c-uvvm-ps-help| replace:: :option:`-Help <compile-uvvm.ps1 -Help>`
.. |c-uvvm-ps-clean| replace:: :option:`-Clean <compile-uvvm.ps1 -Clean>`
.. |c-uvvm-ps-all| replace:: :option:`-All <compile-uvvm.ps1 -All>`
.. |c-uvvm-ps-ghdl| replace:: :option:`-GHDL <compile-uvvm.ps1 -GHDL>`
.. |c-uvvm-ps-questa| replace:: :option:`-Questa <compile-uvvm.ps1 -Questa>`

+--------------------------------------+-------------------------------------------------------------------------------+
| Common Option                        | Parameter Description                                                         |
+================+=====================+===============================================================================+
| |c-uvvm-ps-h|  | |c-uvvm-ps-help|    | Print embedded help page(s).                                                  |
+----------------+---------------------+-------------------------------------------------------------------------------+
| |c-uvvm-ps-c|  | |c-uvvm-ps-clean|   | Clean-up directories.                                                         |
+----------------+---------------------+-------------------------------------------------------------------------------+
| |c-uvvm-ps-a|  | |c-uvvm-ps-all|     | Compile for all simulators.                                                   |
+----------------+---------------------+-------------------------------------------------------------------------------+
|                | |c-uvvm-ps-ghdl|    | Compile for GHDL.                                                             |
+----------------+---------------------+-------------------------------------------------------------------------------+
|                | |c-uvvm-ps-questa|  | Compile for QuestaSim.                                                        |
+----------------+---------------------+-------------------------------------------------------------------------------+

.. # ===========================================================================================================================================================
   .. index::
      pair: Pre-compilation; VUnit

   .. _USING:PreCompile:ThirdParty:VUnit:

   VUnit
   =====

   On Linux
   --------

   .. code-block:: Bash

      # Example 1 - Compile for all Simulators
      ./tools/precompile/compile-vunit.sh --all
      # Example 2 - Compile only for GHDL
      ./tools/precompile/compile-vunit.sh --ghdl

   **List of command line arguments:**

   .. |c-vunit-sh-h| replace:: :option:`-h <compile-vunit.sh -h>`
   .. |c-vunit-sh-c| replace:: :option:`-c <compile-vunit.sh -c>`
   .. |c-vunit-sh-a| replace:: :option:`-a <compile-vunit.sh -a>`
   .. |c-vunit-sh-help| replace:: :option:`--help <compile-vunit.sh --help>`
   .. |c-vunit-sh-clean| replace:: :option:`--clean <compile-vunit.sh --clean>`
   .. |c-vunit-sh-all| replace:: :option:`--all <compile-vunit.sh --all>`
   .. |c-vunit-sh-ghdl| replace:: :option:`--ghdl <compile-vunit.sh --ghdl>`
   .. |c-vunit-sh-questa| replace:: :option:`--questa <compile-vunit.sh --questa>`

   +----------------------------------------+-----------------------------------------------------------------------------+
   | Common Option                          | Parameter Description                                                       |
   +=================+======================+=============================================================================+
   | |c-vunit-sh-h|  | |c-vunit-sh-help|    | Print embedded help page(s).                                                |
   +-----------------+----------------------+-----------------------------------------------------------------------------+
   | |c-vunit-sh-c|  | |c-vunit-sh-clean|   | Clean-up directories.                                                       |
   +-----------------+----------------------+-----------------------------------------------------------------------------+
   | |c-vunit-sh-a|  | |c-vunit-sh-all|     | Compile for all simulators.                                                 |
   +-----------------+----------------------+-----------------------------------------------------------------------------+
   |                 | |c-vunit-sh-ghdl|    | Compile for GHDL.                                                           |
   +-----------------+----------------------+-----------------------------------------------------------------------------+
   |                 | |c-vunit-sh-questa|  | Compile for QuestaSim.                                                      |
   +-----------------+----------------------+-----------------------------------------------------------------------------+


   On Windows
   ----------

   .. code-block:: PowerShell

      # Example 1 - Compile for all Simulators
      .\tools\precompile\compile-vunit.ps1 -All
      # Example 2 - Compile only for GHDL
      .\tools\precompile\compile-vunit.ps1 -GHDL

   **List of command line arguments:**

   .. |c-vunit-ps-h| replace:: ``-h``
   .. |c-vunit-ps-c| replace:: ``-c``
   .. |c-vunit-ps-a| replace:: ``-a``
   .. |c-vunit-ps-help| replace:: :option:`-Help <compile-vunit.ps1 -Help>`
   .. |c-vunit-ps-clean| replace:: :option:`-Clean <compile-vunit.ps1 -Clean>`
   .. |c-vunit-ps-all| replace:: :option:`-All <compile-vunit.ps1 -All>`
   .. |c-vunit-ps-ghdl| replace:: :option:`-GHDL <compile-vunit.ps1 -GHDL>`
   .. |c-vunit-ps-questa| replace:: :option:`-Questa <compile-vunit.ps1 -Questa>`

   +----------------------------------------+-------------------------------------------------------------------------------+
   | Common Option                          | Parameter Description                                                         |
   +=================+======================+===============================================================================+
   | |c-vunit-ps-h|  | |c-vunit-ps-help|    | Print embedded help page(s).                                                  |
   +-----------------+----------------------+-------------------------------------------------------------------------------+
   | |c-vunit-ps-c|  | |c-vunit-ps-clean|   | Clean-up directories.                                                         |
   +-----------------+----------------------+-------------------------------------------------------------------------------+
   | |c-vunit-ps-a|  | |c-vunit-ps-all|     | Compile for all simulators.                                                   |
   +-----------------+----------------------+-------------------------------------------------------------------------------+
   |                 | |c-vunit-ps-ghdl|    | Compile for GHDL.                                                             |
   +-----------------+----------------------+-------------------------------------------------------------------------------+
   |                 | |c-vunit-ps-questa|  | Compile for QuestaSim.                                                        |
   +-----------------+----------------------+-------------------------------------------------------------------------------+

.. # ===========================================================================================================================================================
.. index::
   pair: Pre-compilation; Simulator Adapters

.. _USING:PreCompile:Adapter:

Simulator Adapters
****************************************************************************************************************************************************************

.. index::
   pair: Pre-compilation; Cocotb

.. _USING:PreCompile:Adapter:Cocotb:

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

.. |c-cocotb-sh-h| replace:: :option:`-h <compile-cocotb.sh -h>`
.. |c-cocotb-sh-c| replace:: :option:`-c <compile-cocotb.sh -c>`
.. |c-cocotb-sh-a| replace:: :option:`-a <compile-cocotb.sh -a>`
.. |c-cocotb-sh-help| replace:: :option:`--help <compile-cocotb.sh --help>`
.. |c-cocotb-sh-clean| replace:: :option:`--clean <compile-cocotb.sh --clean>`
.. |c-cocotb-sh-all| replace:: :option:`--all <compile-cocotb.sh --all>`
.. |c-cocotb-sh-ghdl| replace:: :option:`--ghdl <compile-cocotb.sh --ghdl>`
.. |c-cocotb-sh-questa| replace:: :option:`--questa <compile-cocotb.sh --questa>`

+----------------------------------------+-----------------------------------------------------------------------------+
| Common Option                          | Parameter Description                                                       |
+=================+======================+=============================================================================+
| |c-cocotb-sh-h| | |c-cocotb-sh-help|   | Print embedded help page(s).                                                |
+-----------------+----------------------+-----------------------------------------------------------------------------+
| |c-cocotb-sh-c| | |c-cocotb-sh-clean|  | Clean-up directories.                                                       |
+-----------------+----------------------+-----------------------------------------------------------------------------+
| |c-cocotb-sh-a| | |c-cocotb-sh-all|    | Compile for all simulators.                                                 |
+-----------------+----------------------+-----------------------------------------------------------------------------+
|                 | |c-cocotb-sh-ghdl|   | Compile for GHDL.                                                           |
+-----------------+----------------------+-----------------------------------------------------------------------------+
|                 | |c-cocotb-sh-questa| | Compile for QuestaSim.                                                      |
+-----------------+----------------------+-----------------------------------------------------------------------------+


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

.. |c-cocotb-ps-h| replace:: ``-h``
.. |c-cocotb-ps-c| replace:: ``-c``
.. |c-cocotb-ps-a| replace:: ``-a``
.. |c-cocotb-ps-help| replace:: :option:`-Help <compile-cocotb.ps1 -Help>`
.. |c-cocotb-ps-clean| replace:: :option:`-Clean <compile-cocotb.ps1 -Clean>`
.. |c-cocotb-ps-all| replace:: :option:`-All <compile-cocotb.ps1 -All>`
.. |c-cocotb-ps-ghdl| replace:: :option:`-GHDL <compile-cocotb.ps1 -GHDL>`
.. |c-cocotb-ps-questa| replace:: :option:`-Questa <compile-cocotb.ps1 -Questa>`

+----------------------------------------+-----------------------------------------------------------------------------+
| Common Option                          | Parameter Description                                                       |
+=================+======================+=============================================================================+
| |c-cocotb-ps-h| | |c-cocotb-ps-help|   | Print embedded help page(s).                                                |
+-----------------+----------------------+-----------------------------------------------------------------------------+
| |c-cocotb-ps-c| | |c-cocotb-ps-clean|  | Clean-up directories.                                                       |
+-----------------+----------------------+-----------------------------------------------------------------------------+
| |c-cocotb-ps-a| | |c-cocotb-ps-all|    | Compile for all simulators.                                                 |
+-----------------+----------------------+-----------------------------------------------------------------------------+
|                 | |c-cocotb-ps-ghdl|   | Compile for GHDL.                                                           |
+-----------------+----------------------+-----------------------------------------------------------------------------+
|                 | |c-cocotb-ps-questa| | Compile for QuestaSim.                                                      |
+-----------------+----------------------+-----------------------------------------------------------------------------+

.. #

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

