.. _USING:Integration:

Integrating PoC into Projects
#############################

.. contents:: Contents of this page
   :local:
   :depth: 2


.. _USING:Integration:GitSubmodule:

As a Git submodule
******************

The following command line instructions will integrate PoC into a existing Git
repository and register PoC as a Git submodule. Therefore a directory ``lib\PoC\``
is created and the PoC-Library is cloned as a Git submodule into that directory.


On Linux
========

.. code-block:: Bash

   cd ProjectRoot
   mkdir lib
   cd lib
   git submodule add https://github.com/VLSI-EDA/PoC.git PoC
   cd PoC
   git remote rename origin github
   cd ../..
   git add .gitmodules lib\PoC
   git commit -m "Added new git submodule PoC in 'lib/PoC' (PoC-Library)."

On OS X
========

Please see the Linux instructions.


On Windows
==========

.. NOTE::

   All Windows command line instructions are intended for :program:`Windows PowerShell`,
   if not marked otherwise. So executing the following instructions in Windows
   Command Prompt (:program:`cmd.exe`) won't function or result in errors! See
   the :doc:`Requirements section </UsingPoC/Requirements>` on where to
   download or update PowerShell.

.. code-block:: powershell

   cd ProjectRoot
   mkdir lib | cd
   git submodule add https://github.com/VLSI-EDA/PoC.git PoC
   cd PoC
   git remote rename origin github
   cd ..\..
   git add .gitmodules lib\PoC
   git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."

.. seealso::
   :doc:`Configuring PoC on a Local System </UsingPoC/PoCConfiguration>`

   :doc:`Create PoC's VHDL Configuration Files </UsingPoC/VHDLConfiguration>`




.. #
   ## 3. Creating PoC's my_config and my_project Files

   The PoC-Library needs two VHDL files for it's configuration. These files are used
   to determine the most suitable implementation depending on the provided platform
   information.

    1. The **my_config** file can easily be created from a template file provided by
       PoC in `<PoCRoot>\src\common\my_config.vhdl.template`.

       The file should to be copyed into a projects source directory and rename into
       `my_config.vhdl`. This file should be included into version control systems
       and shared with other systems. my_config.vhdl defines two global constants,
       which need to be adjusted:

       ```VHDL
       constant MY_BOARD   : string   := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
       constant MY_DEVICE  : string   := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3
       ```


   Source file: `common/my_config.vhdl.template <https://github.com/VLSI-EDA/PoC/blob/master/src/common/my_config.vhdl.template>`_


       The easiest way is to define a board name and set `MY_DEVICE` to `None`. So
       the device name is infered from the board information stored in `<PoCRoot>\src\common\board.vhdl`.
       If the requested board is not known to PoC or it's custom made, then set
       `MY_BOARD` to `Custom` and `MY_DEVICE` to the full FPGA device string.

       ##### Example 1: A "Stratix II GX Audio Video Development Kit" board:

       ```VHDL
       constant MY_BOARD  : string	:= "S2GXAV";  -- Stratix II GX Audio Video Development Kit
       constant MY_DEVICE : string	:= "None";    -- infer from MY_BOARD
       ```

       ##### Example 2: A custom made Spartan-6 LX45 board:

       ```VHDL
       constant MY_BOARD  : string	:= "Custom";
       constant MY_DEVICE : string	:= "XC6SLX45-3CSG324";
       ```

    2. The **my_project** file can also be created from a template provided by PoC
       in `<PoCRoot>\src\common\my_project.vhdl.template`.

       The file should to be copyed into a projects source directory and rename into
       `my_project.vhdl`. This file **must not** be included into version control
       systems - it's private to a host computer. my_project.vhdl defines two global
       constants, which need to be adjusted:

       ```VHDL
       constant MY_PROJECT_DIR       : string  := "CHANGE THIS";   -- e.g. "d:/vhdl/myproject/", "/home/me/projects/myproject/"
   	constant MY_OPERATING_SYSTEM  : string  := "CHANGE THIS";   -- e.g. "WINDOWS", "LINUX"
       ```

       ##### Example 1: A Windows System:

       ```VHDL
       constant MY_PROJECT_DIR       : string  := "D:/git/GitHub/PoC/";
   	constant MY_OPERATING_SYSTEM  : string  := "WINDOWS";
       ```

       ##### Example 2: A Debian System:

       ```VHDL
       constant MY_PROJECT_DIR       : string  := "/home/lehmann/git/GitHub/PoC/";
   	constant MY_OPERATING_SYSTEM  : string  := "LINUX";
       ```

   ## 4. Compiling shipped Xilinx IP cores to Netlists

   The PoC-Library are shipped with some pre-configured IP cores from Xilinx. These
   IP cores are shipped as \*.xco files and need to be compiled to netlists (\*.ngc
   files) and there auxillary files (\*.ncf files; \*.vhdl files; ...). This can be
   done by invoking `PoC.py` through one of the provided wrapper scripts:
   poc.[sh|ps1].

   > **Is PoC already configured on the system?** If not, run the following
   > configuration step, to tell PoC which tool chains are installed and where.
   > Follow the instructions on the screen. See the [Configuration](Configuration)
   > wiki page for more details.
   >
   > ```powershell
   > cd <PoCRoot>
   > .\poc.ps1 configure
   > ```

   Compiling needed IP cores from PoC for a KC705 board:

   ##### Linux:

   ```Bash
   cd <ProjectRoot>
   cd lib/PoC
   for i in `seq 1 15`; do
     ./poc.sh coregen PoC.xil.ChipScopeICON_$i --board=KC705
   done
   ```

   ##### Windows (PowerShell):

   ```PowerShell
   cd <ProjectRoot>
   cd lib\PoC
   foreach ($i in 1..15) {
     .\poc.ps1 coregen PoC.xil.ChipScopeICON_$i --board=KC705
   }
   ```

