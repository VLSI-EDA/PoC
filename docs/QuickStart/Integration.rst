Integrating PoC into Projects
*****************************

**The PoC-Library** is meant to be integrated into HDL projects. Therefore it's recommended to create a library folder and add the PoC-Library as a git
submodule. After the repository linking is done, some short configuration steps are required to setup paths and tool chains. The following command line
instructions show a short example on how to integrate PoC. A detailed list of steps can be found on the `Integration] page.

Adding the Library as a git submodule
=========================================

The following command line instructions will create the folder ``lib\PoC\`` and clone
the PoC-Library as a git [submodule] into that folder.

.. code-block:: powershell

   cd <ProjectRoot>
   mkdir lib | cd
   git submodule add git@github.com:VLSI-EDA/PoC.git PoC
   cd PoC
   git remote rename origin github
   cd ..\..
   git add .gitmodules lib\PoC
   git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."

.. http://git-scm.com/book/en/v2/Git-Tools-Submodules

Configuring PoC
===================

**The PoC-Library** needs to be configured.

.. code-block:: powershell
   
   cd <ProjectRoot>
   cd lib\PoC\
   .\poc.ps1 configure


Creating PoC's my_config and my_project Files
=================================================

**The PoC-Library** needs two VHDL files for it's configuration. These files are used to determine the most suitable implementation depending on the provided
platform information. Copy these two template files into your project's source folder. Rename these files to *.vhdl and configure the VHDL constants in these
files.

.. code-block:: powershell
   
   cd <ProjectRoot>
   cp lib\PoC\src\common\my_config.vhdl.template src\common\my_config.vhdl
   cp lib\PoC\src\common\my_project.vhdl.template src\common\my_project.vhdl

``my_config.vhdl`` defines two global constants, which need to be adjusted:

.. code-block:: vhdl
   
   constant MY_BOARD            : string := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
   constant MY_DEVICE           : string := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3

``my_project.vhdl`` also defines two global constants, which need to be adjusted:

.. code-block:: vhdl
   
   constant MY_PROJECT_DIR      : string := "CHANGE THIS"; -- e.g. d:/vhdl/myproject/, /home/me/projects/myproject/"
   constant MY_OPERATING_SYSTEM : string := "CHANGE THIS"; -- e.g. WINDOWS, LINUX


Compile shipped Xilinx IP cores (*.xco files) to Netlists
=============================================================

**The PoC-Library** is shipped with some pre-configured IP cores from Xilinx. These IP cores are shipped as \*.xco files and need to be compiled to netlists
(\*.ngc files) and there auxillary files (\*.ncf files; \*.vhdl files; ...). This can be done by invoking PoC's Service Tool through one of the provided wrapper
scripts: ``poc.[sh|ps1]``.

The following example compiles ``PoC.xil.ChipScopeICON_1`` from ``<PoCRoot>\src\xil\xil_ChipScopeICON_1.xco`` for a Kintex-7 325T device into
``<PoCRoot>/netlist/XC7K325T-2FFG900/xil/``.

.. code-block:: powershell
   
   cd <PoCRoot>/netlist
   ..\poc.ps1 coregen PoC.xil.ChipScopeICON_1 --board=KC705

	 
	 
Table of Content:
--------------------------------------------------------------------------------
 1. [Adding the Library as a git submodule](#1-adding-the-library-as-a-git-submodule)
 2. [Configuring PoC on a Local System](#2-configuring-poc-on-a-local-system)
 3. [Creating PoC's my_config and my_project Files](#3-creating-pocs-my_config-and-my_project-files)
 4. [Compiling shipped Xilinx IPCores to Netlists](#4-compiling-shipped-xilinx-ip-cores-to-netlists)

--------------------------------------------------------------------------------

> All Windows command line instructions are intended for **Windows PowerShell**,
> if not marked otherwise. So executing the following instructions in Windows
> Command Prompt (`cmd.exe`) won't function or result in errors! See the
> [Requirements](Requirements) wiki page on where to download or update PowerShell.

**The PoC-Library** is meant to be integrated into HDL projects. Therefore it's
recommended to create a library folder and add the PoC-Library as a git submodule.
After the repository linking is done, some short configuration steps are required
to setup paths and tool chains.

 - Step 1: Link the PoC-Library as a git submodule to a project repo.
 - Step 2: Run PoC's configuration routine to setup paths and tool chains.
 - Step 3: Create a my_config and a my_project file from template.
 - Step 4: Run netlist generation for pre-configured IP cores (optional).


## 1. Adding the Library as a git submodule

The following command line instructions will create a library folder `lib\` and
clone PoC as a git [submodule][git_submod] into the subfolder `lib\PoC\`.

##### Linux:

```Bash
cd <ProjectRoot>
mkdir lib
cd lib
git submodule add git@github.com:VLSI-EDA/PoC.git PoC
cd PoC
git remote rename origin github
cd ../..
git add .gitmodules lib/PoC
git commit -m "Added new git submodule PoC in 'lib/PoC' (PoC-Library)."
```

##### Windows (PowerShell):

```PowerShell
cd <ProjectRoot>
mkdir lib | cd
git submodule add git@github.com:VLSI-EDA/PoC.git PoC
cd PoC
git remote rename origin github
cd ..\..
git add .gitmodules lib\PoC
git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."
```

 [git_submod]: http://git-scm.com/book/en/v2/Git-Tools-Submodules


## 2. Configuring PoC on a Local System

To explore PoC's full potential, it's required to configure some paths and synthesis
or simulation tool chains. See [Configuration](Configuration) for more details.

```PowerShell
cd <ProjectRoot>
cd lib\PoC\
.\poc.ps1 configure
```


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

	 