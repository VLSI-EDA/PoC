.. _USING:VHDLConf:

Creating my_config/my_project.vhdl
##################################

The PoC-Library needs two VHDL files for its configuration. These files are
used to determine the most suitable implementation depending on the provided
platform information. These files are also used to select appropiate work
arounds.


.. _USING:VHDLConf:myconfig:

Create my_config.vhdl
*********************

The **my_config.vhdl** file can easily be created from the template file
``my_config.vhdl.template`` provided by PoC in ``PoCRoot\src\common``.
(View source on `GitHub <https://github.com/VLSI-EDA/PoC/blob/master/src/common/my_config.vhdl.template>`_.)
Copy this file into the project's source directory and rename it to
``my_config.vhdl``.

This file should be included in version control systems and shared with other
systems. ``my_config.vhdl`` defines three global constants, which need to be
adjusted:

.. code-block:: VHDL

   constant MY_BOARD   : string  := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
   constant MY_DEVICE  : string  := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3
   constant MY_VERBOSE : boolean := FALSE;         -- activate report statements in VHDL subprograms

The easiest way is to define a board name and set ``MY_DEVICE`` to ``None``.
So the device name is infered from the board information stored in ``PoCRoot\src\common\config.vhdl``.
If the requested board is not known to PoC or it's custom made, then set
``MY_BOARD`` to ``Custom`` and ``MY_DEVICE`` to the full FPGA device string.

**Example 1: A "Stratix II GX Audio Video Development Kit" board:**

.. code-block:: VHDL

   constant MY_BOARD  : string := "S2GXAV";  -- Stratix II GX Audio Video Development Kit
   constant MY_DEVICE : string := "None";    -- infer from MY_BOARD

**Example 2: A custom made Spartan-6 LX45 board:**

.. code-block:: VHDL

   constant MY_BOARD  : string := "Custom";
   constant MY_DEVICE : string := "XC6SLX45-3CSG324";


.. _USING:VHDLConf:myproject:

Create my_project.vhdl
**********************

The **my_project.vhdl** file can also be created from a template file
``my_project.vhdl.template`` provided by PoC in ``PoCRoot\src\common``.

The file should to be copyed into a projects source directory and renamed
into ``my_project.vhdl``. This file **must not** be included into version
control systems -- it's private to a computer. ``my_project.vhdl`` defines two
global constants, which need to be adjusted:

.. code-block:: VHDL

   constant MY_PROJECT_DIR      : string := "CHANGE THIS"; -- e.g. "d:/vhdl/myproject/", "/home/me/projects/myproject/"
   constant MY_OPERATING_SYSTEM : string := "CHANGE THIS"; -- e.g. "WINDOWS", "LINUX"

**Example 1: A Windows System:**

.. code-block:: VHDL

   constant MY_PROJECT_DIR      : string := "D:/git/GitHub/PoC/";
   constant MY_OPERATING_SYSTEM : string := "WINDOWS";

**Example 2: A Debian System:**

.. code-block:: VHDL

   constant MY_PROJECT_DIR      : string := "/home/paebbels/git/GitHub/PoC/";
   constant MY_OPERATING_SYSTEM : string := "LINUX";

.. seealso::
   :doc:`Running one or more testbenches </UsingPoC/Simulation>`
      The installation can be checked by running one or more of PoC's testbenches.
   :doc:`Running one or more netlist generation flows </UsingPoC/Synthesis>`
      The installation can also be checked by running one or more of PoC's
      synthesis flows.
