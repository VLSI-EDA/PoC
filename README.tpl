{@GENERATED_HEADER@}
# The PoC-Library

[![Python Infrastructure tested by Landscape.io](https://landscape.io/github/VLSI-EDA/PoC/{@BRANCH@}/landscape.svg?style=flat)](https://landscape.io/github/VLSI-EDA/PoC/{@BRANCH@})
[![Build Status by Travis-CI](https://travis-ci.org/VLSI-EDA/PoC.svg?branch={@BRANCH@})](https://travis-ci.org/VLSI-EDA/PoC/branches)
[![Documentation Status](https://readthedocs.org/projects/poc-library/badge/?version=latest)](http://poc-library.readthedocs.io/en/latest/?badge=latest)
[![Join the chat at https://gitter.im/VLSI-EDA/PoC](https://badges.gitter.im/VLSI-EDA/PoC.svg)](https://gitter.im/VLSI-EDA/PoC?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
![Latest tag](https://img.shields.io/github/tag/VLSI-EDA/PoC.svg?style=flat)
[![Latest release](https://img.shields.io/github/release/VLSI-EDA/PoC.svg?style=flat)](https://github.com/VLSI-EDA/PoC/releases)
[![Apache License 2.0](https://img.shields.io/github/license/VLSI-EDA/PoC.svg?style=flat)](LICENSE.md)


This library is published and maintained by **Chair for VLSI Design, Diagnostics and Architecture** - 
Faculty of Computer Science, Technische Universität Dresden, Germany 
**http://vlsi-eda.inf.tu-dresden.de**

![Logo: Technische Universität Dresden](https://github.com/VLSI-EDA/PoC/wiki/images/logo_tud.gif)

Table of Content:
--------------------------------------------------------------------------------
 1. [Overview](#1-overview)
 2. [Download](#2-download)
 3. [Requirements](#3-requirements)
 4. [Dependencies](#4-dependencies)
 5. [Configuring PoC on a Local System (Stand Alone)](#5-configuring-poc-on-a-local-system-stand-alone)
 6. [Integrating PoC into Projects](#6-integrating-poc-into-projects)
 7. [Using PoC](#7-using-poc)
 8. [Updating PoC](#8-updating-poc)
 9. [References](#9-references)

--------------------------------------------------------------------------------

## 1 Overview

PoC - “Pile of Cores” provides implementations for often required hardware functions such as Arithmetic Units, Caches, Clock-Domain-Crossing Circuits, FIFOs, RAM wrappers, and I/O Controllers. The hardware modules are typically provided as VHDL or Verilog source code, so it can be easily re-used in a variety of hardware designs.

All hardware modules use a common set of VHDL packages to share new VHDL types, sub-programs and constants. Additionally, a set of simulation helper packages eases the writing of testbenches. Because PoC hosts a huge amount of IP cores, all cores are grouped into sub-namespaces to build a better hierachy.

Various simulation and synthesis tool chains are supported to interoperate with PoC. To generalize all supported free and commercial vendor tool chains, PoC is shipped with a Python based Infrastruture to offer a command line based frontend.


## 2 Requirements and Dependencies

The PoC-Library comes with some scripts to ease most of the common tasks, like running testbenches or
generating IP cores. PoC uses Python 3 as a platform independent scripting environment. All Python
scripts are wrapped in Bash or PowerShell scripts, to hide some platform specifics of Darwin, Linux or
Windows. See [Requirements][rtfd:using/requirements] for
further details.

 [rtfd:using/requirements]: http://poc-library.readthedocs.io/en/{@BRANCH@}/UsingPoC/Requirements.html

##### PoC requires:

* A [supported synthesis tool chain][rtfd:whatis/toolchains], if you want to synthezise IP cores.
* A [supported simulator too chain][rtfd:whatis/toolchains], if you want to simulate IP cores.
* The Python3 programming language and runtime, if you want to use PoC's infrastructure.
* A shell to execute shell scripts:
  * Bash on Linux and OS X
  * PowerShell on Windows

 [rtfd:whatis/toolchains]: http://poc-library.readthedocs.io/en/{@BRANCH@}/WhatIsPoC/SupportedToolChains.html

##### PoC optionally requires:

* Git command line tools or a Git GUI, if you want to check out the latest '{@BRANCH@}' or 'release' branch.


##### PoC depends on third parts libraries:

* [**Cocotb**][cocotb]  
  A coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python.
* [**OS-VVM**][osvvm]  
  Open Source VHDL Verification Methodology.
* [**VUnit**][vunit]  
  An unit testing framework for VHDL.

All dependencies are available as GitHub repositories and are linked to PoC as Git submodules into
the [PoCRoot\lib](https://github.com/VLSI-EDA/PoC/tree/{@BRANCH@}/lib) directory. See [Third Party
Libraries](http://poc-library.readthedocs.io/en/{@BRANCH@}/Miscelaneous/ThirdParty.html) for more details on these libraries.

 [cocotb]: https://github.com/potentialventures/cocotb
 [osvvm]:	 https://github.com/JimLewis/OSVVM
 [vunit]:	 https://github.com/VUnit/vunit

## 3 Download

The PoC-Library can be downloaded as a [zip-file][github:download] (latest '{@BRANCH@}' branch), cloned with `git clone`
or embedded with `git submodule add` from GitHub. GitHub offers HTTPS and SSH as transfer protocols. See the [Download][rtfd:download] page for further details. The installation directory is referred to as `PoCRoot`.

| Protocol | Git Clone Command                                                 |
| -------- | ----------------------------------------------------------------- |
| HTTPS    | `git clone --recursive https://github.com/VLSI-EDA/PoC.git PoC`   |
| SSH      | `git clone --recursive ssh://git@github.com:VLSI-EDA/PoC.git PoC` |

 [rtfd:download]: http://poc-library.readthedocs.io/en/{@BRANCH@}/UsingPoC/Download.html
 [github:download]: https://github.com/VLSI-EDA/PoC/archive/{@BRANCH@}.zip


## 4 Configuring PoC on a Local System

To explore PoC's full potential, it's required to configure some paths and synthesis or simulation tool chains.
The following commands start a guided configuration process. Please follow the instructions on screen. It's
possible to relaunch the process at any time, for example to register new tools or to update tool versions.
See [Configuration](http://poc-library.readthedocs.io/en/{@BRANCH@}/UsingPoC/PoCConfiguration.html) for more
details. Run the following command line instructions to configure PoC on your local system:

```PowerShell
cd PoCRoot
.\poc.ps1 configure
```

Use the keyboard buttons: `Y` to accept, `N` to decline, `P` to skip/pass a step and `Return` to accept a
default value displayed in brackets.


If you want to check your installation, you can run one of our testbenches as described in [Using PoC -> Simulation][rtfd:using/simulation]

 [rtfd:using/simulation]: http://poc-library.readthedocs.io/en/{@BRANCH@}/UsingPoC/Simulation.html

## 6 Integrating PoC into Projects

**The PoC-Library** is meant to be integrated into HDL projects. Therefore it's
recommended to create a library folder and add the PoC-Library as a git submodule.
After the repository linking is done, some short configuration steps are required
to setup paths and tool chains. The following command line instructions show a
short example on how to integrate PoC. A detailed list of steps can be found on the
[Integration][wiki:integration] wiki page.

#### 6.1 Adding the Library as a git submodule

The following command line instructions will create the folder `lib\PoC\` and clone
the PoC-Library as a git [submodule][git_submod] into that folder.

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

#### 6.2 Configuring PoC

**The PoC-Library** needs to be configured.

```PowerShell
cd <ProjectRoot>
cd lib\PoC\
.\poc.ps1 configure
```

#### 6.3 Creating PoC's my_config and my_project Files

**The PoC-Library** needs two VHDL files for it's configuration. These files are used to
determine the most suitable implementation depending on the provided platform information.
Copy these two template files into your project's source folder. Rename these files to
*.vhdl and configure the VHDL constants in these files.

```PowerShell
cd <ProjectRoot>
cp lib\PoC\src\common\my_config.vhdl.template src\common\my_config.vhdl
cp lib\PoC\src\common\my_project.vhdl.template src\common\my_project.vhdl
```

`my_config.vhdl` defines two global constants, which need to be adjusted:

```VHDL
constant MY_BOARD            : string := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
constant MY_DEVICE           : string := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3
```

`my_project.vhdl` also defines two global constants, which need to be adjusted:

```VHDL
constant MY_PROJECT_DIR      : string := "CHANGE THIS"; -- e.g. d:/vhdl/myproject/, /home/me/projects/myproject/"
constant MY_OPERATING_SYSTEM : string := "CHANGE THIS"; -- e.g. WINDOWS, LINUX
```

#### 6.4 Compile shipped Xilinx IP cores (*.xco files) to Netlists

**The PoC-Library** is shipped with some pre-configured IP cores from Xilinx. These
IP cores are shipped as \*.xco files and need to be compiled to netlists (\*.ngc
files) and there auxillary files (\*.ncf files; \*.vhdl files; ...). This can be
done by invoking PoC's Service Tool through one of the provided wrapper scripts:
`poc.[sh|ps1]`.

The following example compiles `PoC.xil.ChipScopeICON_1` from `<PoCRoot>\src\xil\xil_ChipScopeICON_1.xco`
for a Kintex-7 325T device into `<PoCRoot>/netlist/XC7K325T-2FFG900/xil/`.

```PowerShell
cd <PoCRoot>/netlist
..\poc.ps1 coregen PoC.xil.ChipScopeICON_1 --board=KC705
```

## 7 Using PoC

**The PoC-Library** is structured into several sub-folders naming the purpose of
the folder like [`src`][src] for sources files or [`tb`][tb] for testbench files.
The structure within these folders is always the same and based on PoC's
[sub-namespace tree][wiki:subnamespacetree].

**Main directory overview:**

 -  [`lib`][lib] - Embedded or linked external libraries.
 -  [`netlist`][netlist] - Configuration files and output directory for
    pre-configured netlist synthesis results from vendor IP cores or from complex PoC controllers.
 -  [`py`][py] - Supporting Python scripts.
 -  [`sim`][sim] - Pre-configured waveform views for selected testbenches.
 -  [`src`][src] - PoC's source files grouped into sub-folders according to the [sub-namespace tree][wiki:subnamespacetree].
 -  [`tb`][tb] - Testbench files.
 -  [`tcl`][tcl] - Tcl files.
 -  [`temp`][temp] - A created temporary directors for various tools used by PoC's Python scripts.
 -  [`tools`][tools] - Settings/highlighting files and helpers for supported tools.
 -  [`ucf`][ucf] - Pre-configured constraint files (\*.ucf, \*.xdc, \*.sdc) for supported FPGA boards.
 -  [`xst`][xst] - Configuration files to synthesize PoC modules with Xilinx XST into a netlist.

#### 7.1 Common Notes

All VHDL source files should be compiled into the VHDL library `PoC`.
If not indicated otherwise, all source files can be compiled using the
VHDL-93 or VHDL-2008 language version. Incompatible files are named
`*.v93.vhdl` and `*.v08.vhdl` to denote the highest supported language
version.

#### 7.2 Standalone

#### 7.3 In Altera Quartus II

#### 7.4 In GHDL

#### 7.5 In ModelSim/QuestaSim


#### 7.6 In Xilinx ISE (XST and iSim)

**The PoC-Library** was originally designed for the Xilinx ISE
design flow. The latest version (14.7) is supported and required to
explore PoC's full potential. Don't forget to activate the new
XST parser in new projects and to append the IP core search
directory if generated netlists are used.

 1. **Activating the New Parser in XST** 
    PoC requires XST to use the *new* source file parser, introduced
    with the Virtex-6 FPGA family. It is backward compatible.

    **->** Open the *XST Process Property* window and add `-use_new_parser yes`
    to the option `Other XST Command Line Options`.

 2. **Setting the IP Core Search Directory for Generated Netlists** 
    PoC can generate netlists for bundled source files or for
    pre-configured IP cores. These netlists are copied into the
    `<PoCRoot>\netlist\<DEVICE>` folder. This folder and its subfolders
    need to be added to the IP core search directory.
 
    **->** Open the *XST Process Property* window and append the directory to the `-sd` option.
    **->** Open *Translate Process Property* and append the paths here, too.
    
        D:\git\PoC\netlist\XC7VX485T-2FFG1761|      ↩
        D:\git\PoC\netlist\XC7VX485T-2FFG1761\xil|  ↩
        D:\git\PoC\netlist\XC7VX485T-2FFG1761\sata

    **Note:** The IP core search directory value is a `|` seperated list of directories. A recursive search is not performed, so sub-folders need to be named individually.

#### 7.7 In Xilinx Vivado (Synth and xSim)

**The PoC-Library** has no full Vivado support, because of the incomplete
VHDL-93 support in Vivado's synthesis tool. Especially the incorrect implementation of
physical types causes errors in PoC's I/O modules.

Vivado's simulator xSim is not affected.

**Experimental [`Vivado`](tree/Vivado) Branch:**
We provide a `vivado` branch, which can be used for Vivado synthesis. This branch contains workarounds to let Vivado synthesize our modules. As an effect some interfaces (mostly generics have changed).


## 8 Updating PoC

**The PoC-Library** can be updated by using `git fetch`:

```PowerShell
cd <GitRoot>\PoC
git fetch
# review the commit tree and messages, using the 'treea' alias
git tree --all
# if all changes are OK, do a fast-forward merge
git merge
```


## 9 References

 -  [PoC-Examples][poc_ex]: 
    A list of examples and reference implementations for the PoC-Library
 -  [The Q27 Project][q27]: 
    27-Queens Puzzle: Massively Parellel Enumeration and Solution Counting
 -  [PicoBlaze-Library][pb_lib]: 
    The PicoBlaze-Library offers several PicoBlaze devices and code routines
    to extend a common PicoBlaze environment to a little System on a Chip (SoC
    or SoFPGA).
 -  [PicoBlaze-Examples][pb_ex]: 
    A SoFPGA reference implementation, based on the PoC-Library and the
    PicoBlaze-Library.

 [poc_ex]:  https://github.com/VLSI-EDA/PoC-Examples
 [q27]:			https://github.com/preusser/q27
 [pb_lib]:  https://github.com/Paebbels/PicoBlaze-Library
 [pb_ex]:		https://github.com/Paebbels/PicoBlaze-Examples
 
If you are using the PoC-Library, please let us know. We are grateful for
your project's reference.

 [lib]:					lib
 [netlist]:			netlist
 [py]:					py
 [sim]:					sim
 [src]:					src
 [tb]:					tb
 [tcl]:					tcl
 [temp]:				temp
 [tools]:				tools
 [ucf]:					ucf
 [xst]:					xst

 [wiki:download]:				https://github.com/VLSI-EDA/PoC/wiki/Download
 [wiki:requirements]:		https://github.com/VLSI-EDA/PoC/wiki/Requirements
 [wiki:configuration]:	https://github.com/VLSI-EDA/PoC/wiki/Configuration
 [wiki:integration]:		https://github.com/VLSI-EDA/PoC/wiki/Integration

 [wiki:subnamespacetree]:	https://github.com/VLSI-EDA/PoC/wiki/SubnamespaceTree
