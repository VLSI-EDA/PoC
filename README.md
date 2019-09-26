<!--- DO NOT EDIT! This file is generated from .tpl --->
# The PoC-Library

[![Build Status by Travis-CI](https://travis-ci.org/VLSI-EDA/PoC.svg?branch=release)](https://travis-ci.org/VLSI-EDA/PoC/branches)
[![Build status by AppVeyor](https://ci.appveyor.com/api/projects/status/r5dtv6amsppigpsp/branch/release?svg=true)](https://ci.appveyor.com/project/Paebbels/poc/branch/release)
[![Documentation Status](https://readthedocs.org/projects/poc-library/badge/?version=latest)](http://poc-library.readthedocs.io/en/latest/?badge=latest)
[![Python Infrastructure tested by Landscape.io](https://landscape.io/github/VLSI-EDA/PoC/release/landscape.svg?style=flat)](https://landscape.io/github/VLSI-EDA/PoC/release)
[![Requirements Status](https://requires.io/github/VLSI-EDA/PoC/requirements.svg?branch=release)](https://requires.io/github/VLSI-EDA/PoC/requirements/?branch=release) [![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FVLSI-EDA%2FPoC.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2FVLSI-EDA%2FPoC?ref=badge_shield)
 
[![Join the chat at https://gitter.im/VLSI-EDA/PoC](https://badges.gitter.im/VLSI-EDA/PoC.svg)](https://gitter.im/VLSI-EDA/PoC)
[![Subscribe for news at https://gitter.im/VLSI-EDA/News](https://img.shields.io/badge/news-Subscribe%20to%20VLSI--EDA%2FNews-orange.svg)](https://gitter.im/VLSI-EDA/News)  
![Latest tag](https://img.shields.io/github/tag/VLSI-EDA/PoC.svg?style=flat)
[![Latest release](https://img.shields.io/github/release/VLSI-EDA/PoC.svg?style=flat)](https://github.com/VLSI-EDA/PoC/releases)
[![Apache License 2.0](https://img.shields.io/github/license/VLSI-EDA/PoC.svg?style=flat)](LICENSE.md)


This library is published and maintained by **Chair for VLSI Design, Diagnostics and Architecture** - 
Faculty of Computer Science, Technische Universität Dresden, Germany 
**http://vlsi-eda.inf.tu-dresden.de**

![Technische Universität Dresden](https://github.com/VLSI-EDA/PoC/wiki/images/logo_tud.gif)

Table of Content:
--------------------------------------------------------------------------------
 1. [Overview](#1-overview)
 2. [Quick Start Guide](#2-quick-start-guide)  
    2.1. [Requirements and Dependencies](#21-requirements-and-dependencies)  
    2.2. [Download](#22-download)  
    2.3. [Configuring PoC on a Local System](#23-configuring-poc-on-a-local-system)  
    2.4. [Integration](#24-integration)  
    2.5. [Updating](#25-updating)
 3. [Common Notes](#3-common-notes)
 4. [Cite the PoC-Library](#4-cite-the-poc-library)

--------------------------------------------------------------------------------

## 1 Overview

PoC - “Pile of Cores” provides implementations for often required hardware functions such as
Arithmetic Units, Caches, Clock-Domain-Crossing Circuits, FIFOs, RAM wrappers, and I/O Controllers.
The hardware modules are typically provided as VHDL or Verilog source code, so it can be easily
re-used in a variety of hardware designs.

All hardware modules use a common set of VHDL packages to share new VHDL types, sub-programs and
constants. Additionally, a set of simulation helper packages eases the writing of testbenches.
Because PoC hosts a huge amount of IP cores, all cores are grouped into sub-namespaces to build a
clear hierachy.

Various simulation and synthesis tool chains are supported to interoperate with PoC. To generalize
all supported free and commercial vendor tool chains, PoC is shipped with a Python based
infrastructure to offer a command line based frontend.


## 2 Quick Start Guide

This **Quick Start Guide** gives a fast and simple introduction into PoC. All topics can be found in
the [Using PoC][201] section at [ReadTheDocs.io][202] with much more details and examples.


### 2.1 Requirements and Dependencies

The PoC-Library comes with some scripts to ease most of the common tasks, like running testbenches or
generating IP cores. PoC uses Python 3 as a platform independent scripting environment. All Python
scripts are wrapped in Bash or PowerShell scripts, to hide some platform specifics of Darwin, Linux or
Windows. See [Requirements][211] for further details.

[211]: http://poc-library.readthedocs.io/en/latest/UsingPoC/Requirements.html


#### PoC requires:
 -  A [supported synthesis tool chain][2111], if you want to synthezise IP cores.
 -  A [supported simulator tool chain][2112], if you want to simulate IP cores.
 -  The **Python 3** programming language and runtime, if you want to use PoC's infrastructure.
 -  A shell to execute shell scripts:
    -  **Bash** on Linux and OS X
    -  **PowerShell** on Windows

[2111]: http://poc-library.readthedocs.io/en/latest/WhatIsPoC/SupportedToolChains.html
[2112]: http://poc-library.readthedocs.io/en/latest/WhatIsPoC/SupportedToolChains.html


#### PoC optionally requires:
 -  **Git command line** tools or
 -  **Git User Interface**, if you want to check out the latest 'master' or 'release' branch.


#### PoC depends on third part libraries:
 -  [Cocotb][2131]  
    A coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python.
 -  [OS-VVM][2132]  
    Open Source VHDL Verification Methodology.
 -  [UVVM][2133]  
    Universal VHDL Verification Methodology.
 -  [VUnit][2134]  
    An unit testing framework for VHDL.
  
All dependencies are available as GitHub repositories and are linked to PoC as Git submodules into the
[`PoCRoot\lib`][205] directory. See [Third Party Libraries][206] for more details on these libraries.

[2131]: https://github.com/potentialventures/cocotb
[2132]: https://github.com/JimLewis/OSVVM
[2133]: https://github.com/UVVM/UVVM_All
[2134]: https://github.com/VUnit/vunit

[201]: http://poc-library.readthedocs.io/en/latest/UsingPoC/index.html
[202]: http://poc-library.readthedocs.io/
[205]: https://github.com/VLSI-EDA/PoC/tree/release/lib
[206]: http://poc-library.readthedocs.io/en/latest/Miscelaneous/ThirdParty.html


### 2.2 Download

The PoC-Library can be downloaded as a [zip-file][221] (latest 'release' branch), cloned with `git clone`
or embedded with `git submodule add` from GitHub. GitHub offers HTTPS and SSH as transfer protocols. See
the [Download][222] page for further details. The installation directory is referred to as `PoCRoot`.

Protocol | Git Clone Command
-------- | :-----------------------------------------------------------
HTTPS    | `git clone --recursive https://github.com/VLSI-EDA/PoC.git PoC`
SSH      | `git clone --recursive ssh://git@github.com:VLSI-EDA/PoC.git PoC`

[221]: https://github.com/VLSI-EDA/PoC/archive/release.zip
[222]: http://poc-library.readthedocs.io/en/latest/UsingPoC/Download.html

### 2.3 Configuring PoC on a Local System

To explore PoC's full potential, it's required to configure some paths and synthesis or simulation tool
chains. The following commands start a guided configuration process. Please follow the instructions on
screen. It's possible to relaunch the process at any time, for example to register new tools or to update
tool versions. See [Configuration][231] for more details. Run the following command line instructions to
configure PoC on your local system:

```PowerShell
cd PoCRoot
.\poc.ps1 configure
```

Use the keyboard buttons: `Y` to accept, `N` to decline, `P` to skip/pass a step and `Return` to accept
a default value displayed in brackets.

[231]: http://poc-library.readthedocs.io/en/latest/UsingPoC/PoCConfiguration.html

### 2.4 Integration

The PoC-Library is meant to be integrated into other HDL projects. Therefore it's recommended to create
a library folder and add the PoC-Library as a Git submodule. After the repository linking is done, some
short configuration steps are required to setup paths, tool chains and the target platform. The following
command line instructions show a short example on how to integrate PoC.

#### a) Adding the Library as a Git submodule

The following command line instructions will create the folder `lib\PoC\` and clone the PoC-Library as a
[Git submodule][2411] into that folder. `ProjectRoot` is the directory of the hosting Git. A detailed list
of steps can be found at [Integration][2412].

```powershell
cd ProjectRoot
mkdir lib | cd
git submodule add https://github.com:VLSI-EDA/PoC.git PoC
cd PoC
git remote rename origin github
cd ..\..
git add .gitmodules lib\PoC
git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."
```

[2411]: http://git-scm.com/book/en/v2/Git-Tools-Submodules
[2412]: http://poc-library.readthedocs.io/en/latest/UsingPoC/Integration.html

#### b) Configuring PoC

The PoC-Library should be configured to explore its full potential. See [Configuration][2421] for more
details. The following command lines will start the configuration process:

```powershell
cd ProjectRoot
.\lib\PoC\poc.ps1 configure
```

[2421]: http://poc-library.readthedocs.io/en/latest/UsingPoC/PoCConfiguration.html

#### c) Creating PoC's `my_config.vhdl` and `my_project.vhdl` Files

The PoC-Library needs two VHDL files for its configuration. These files are used to determine the most
suitable implementation depending on the provided target information. Copy the following two template
files into your project's source folder. Rename these files to \*.vhdl and configure the VHDL constants
in the files:

```powershell
cd ProjectRoot
cp lib\PoC\src\common\my_config.vhdl.template src\common\my_config.vhdl
cp lib\PoC\src\common\my_project.vhdl.template src\common\my_project.vhdl
```

[my_config.vhdl](https://github.com/VLSI-EDA/PoC/blob/release/src/common/my_config.vhdl.template) defines
two global constants, which need to be adjusted:

```vhdl
constant MY_BOARD            : string := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
constant MY_DEVICE           : string := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3
```

[my_project.vhdl](https://github.com/VLSI-EDA/PoC/blob/release/src/common/my_project.vhdl.template) also
defines two global constants, which need to be adjusted:

```vhdl
constant MY_PROJECT_DIR      : string := "CHANGE THIS"; -- e.g. d:/vhdl/myproject/, /home/me/projects/myproject/"
constant MY_OPERATING_SYSTEM : string := "CHANGE THIS"; -- e.g. WINDOWS, LINUX
```

Further informations are provided at [Creating my_config/my_project.vhdl][2431].

[2431]: http://poc-library.readthedocs.io/en/latest/UsingPoC/VHDLConfiguration.html

#### d) Adding PoC's Common Packages to a Synthesis or Simulation Project

PoC is shipped with a set of common packages, which are used by most of its modules. These packages are
stored in the `PoCRoot\src\common` directory. PoC also provides a VHDL context in `common.vhdl` , which
can be used to reference all packages at once.


#### e) Adding PoC's Simulation Packages to a Simulation Project

Simulation projects additionally require PoC's simulation helper packages, which are located in the
`PoCRoot\src\sim` directory. Because some VHDL version are incompatible among each other, PoC uses
version suffixes like `*.v93.vhdl` or `*.v08.vhdl` in the file name to denote the supported VHDL version
of a file.


#### f) Compiling Shipped IP Cores

Some IP Cores are shipped as pre-configured vendor IP Cores. If such IP cores shall be used in a HDL
project, it's recommended to use PoC to create, compile and if needed patch these IP cores. See
[Synthesis][2461] for more details.

[2461]: http://poc-library.readthedocs.io/en/latest/UsingPoC/Synthesis.html


### 2.5 Updating

The PoC-Library can be updated by using `git fetch` and `git merge`.

```PowerShell
cd PoCRoot
# update the local repository
git fetch --prune
# review the commit tree and messages, using the 'treea' alias
git treea
# if all changes are OK, do a fast-forward merge
git merge
```

**See also:**
 -  [**Running one or more testbenches**][251]  
    The installation can be checked by running one or more of PoC's testbenches.
 -  [**Running one or more netlist generation flows**][252]  
    The installation can also be checked by running one or more of PoC's synthesis flows.

[251]: http://poc-library.readthedocs.io/en/latest/UsingPoC/Simulation.html
[252]: http://poc-library.readthedocs.io/en/latest/UsingPoC/Synthesis.html 


## 3. Common Notes

**The PoC-Library** is structured into several sub-folders naming the purpose of the folder like
[`src`](src) for sources files or [`tb`](tb) for testbench files. The structure within these folders
is always the same and based on PoC's sub-namespace tree.

**Main directory overview:**

 -  [`lib`](lib) - Embedded or linked external libraries.
 -  [`netlist`](netlist) - Configuration files and output directory for pre-configured netlist synthesis
    results from vendor IP cores or from complex PoC controllers.
 -  [`py`](py) - Supporting Python scripts.
 -  [`sim`](sim) - Pre-configured waveform views for selected testbenches.
 -  [`src`](src) - PoC's source files grouped into sub-folders according to the sub-namespace tree.
 -  [`tb`](tb) - Testbench files.
 -  [`tcl`](tcl) - Tcl files.
 -  [`temp`](temp) - Automatically created temporary directors for various tools used by PoC's Python scripts.
 -  [`tools`](tools) - Settings/highlighting files and helpers for supported tools.
 -  [`ucf`](ucf) - Pre-configured constraint files (\*.ucf, \*.xdc, \*.sdc) for supported FPGA boards.
 -  [`xst`](xst) - Configuration files to synthesize PoC modules with Xilinx XST into a netlist.


All VHDL source files should be compiled into the VHDL library `PoC`. If not indicated otherwise, all
source files can be compiled using the VHDL-93 or VHDL-2008 language version. Incompatible files are
named `*.v93.vhdl` and `*.v08.vhdl` to denote the highest supported language version.


## 4 Cite the PoC-Library

If you are using the PoC-Library, please let us know. We are grateful for your project's reference.
The PoC-Library hosted at [GitHub.com](https://www.github.com). Please use the following
[biblatex](https://www.ctan.org/pkg/biblatex) entry to cite us:

```bibtex
# BibLaTex example entry
@online{poc,
  title={{PoC - Pile of Cores}},
  author={{Chair of VLSI Design, Diagnostics and Architecture}},
  organization={{Technische Universität Dresden}},
  year={2016},
  url={https://github.com/VLSI-EDA/PoC},
  urldate={2016-10-28},
}
```


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FVLSI-EDA%2FPoC.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2FVLSI-EDA%2FPoC?ref=badge_large)