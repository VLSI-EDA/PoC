# The PoC-Library

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

PoC - "Pile of Cores" provides implementations for often required hardware
functions such as FIFOs, RAM wrapper, and ALUs. The hardware modules are
typically provided as VHDL or Verilog source code, so it can be easily re-used
in a variety of hardware designs.

TODO TODO TODO

Related repositories: [PoC-Examples][poc_ex]

 [poc_ex]:  https://github.com/VLSI-EDA/PoC-Examples


## 2 Download

**The PoC-Library** can be downloaded as a [zip-file][download] (latest 'master' branch) or
cloned with `git clone` from GitHub. GitHub offers HTTPS and SSH as transfer protocols.
See the [Download][wiki:download] wiki page for more details.

For SSH protocol use the URL `ssh://git@github.com:VLSI-EDA/PoC.git` or command
line instruction:

```PowerShell
cd <GitRoot>
git clone --recursive ssh://git@github.com:VLSI-EDA/PoC.git PoC
```

For HTTPS protocol use the URL `https://github.com/VLSI-EDA/PoC.git` or command
line instruction:

```PowerShell
cd <GitRoot>
git clone --recursive https://github.com/VLSI-EDA/PoC.git PoC
```

**Note:** The option `--recursive` performs a recursive clone operation for all
linked [git submodules][git_submod]. An additional `git submodule init` and
`git submodule update` call is not needed anymore. 

 [download]: https://github.com/VLSI-EDA/PoC/archive/master.zip
 [git_submod]: http://git-scm.com/book/en/v2/Git-Tools-Submodules

**Note:** The created folder `<GitRoot>\PoC` is used as `<PoCRoot>` in later instructions. 


## 3 Requirements

**The PoC-Library** comes with some scripts to ease most of the common tasks, like
running testbenches or generating IP cores. We choose to use Python as a platform
independent scripting environment. All Python scripts are wrapped in PowerShell
or Bash scripts, to hide some platform specifics of Windows or Linux. See the
[Requirements][wiki:requirements] wiki page for more details and download sources.

##### Common requirements:

 - Programming languages and runtimes:
	- [Python 3][python] (&ge; 3.4):
	     - [colorama][colorama]
 - Synthesis tool chains:
     - Altera Quartus-II &ge; 13.0 or
     - Lattice Diamond or
     - Xilinx ISE 14.7 or
     - Xilinx Vivado (restricted, see [section 7.7](#7.7-in-xilinx-vivado-synth-and-xsim))
 - Simulation tool chains:
     - Aldec Active-HDL or
     - Mentor Graphics ModelSim Altera Edition or
     - Mentor Graphics QuestaSim or
     - Xilinx ISE Simulator 14.7 or
     - Xilinx Vivado Simulator &ge; 2014.1 or
     - [GHDL][ghdl] and [GTKWave][gtkwave]

 [python]:		https://www.python.org/downloads/
 [colorama]:	https://pypi.python.org/pypi/colorama
 [ghdl]:		https://sourceforge.net/projects/ghdl-updates/
 [gtkwave]:		http://gtkwave.sourceforge.net/

##### Linux specific requirements:
 
 - Debian specific:
	- bash is configured as `/bin/sh` ([read more](https://wiki.debian.org/DashAsBinSh))  
      `dpkg-reconfigure dash`
 
##### Windows specific requirements:

 - PowerShell 4.0 ([Windows Management Framework 4.0][wmf40])
    - Allow local script execution ([read more][execpol])  
      `Set-ExecutionPolicy RemoteSigned`
    - PowerShell Community Extensions 3.2 ([pscx.codeplex.com][pscx])

 [wmf40]:   http://www.microsoft.com/en-US/download/details.aspx?id=40855
 [execpol]: https://technet.microsoft.com/en-us/library/hh849812.aspx
 [pscx]:    http://pscx.codeplex.com/


## 4 Dependencies

**The PoC-Library** depends on:

 - [**OS-VVM**][osvvm] - Open Source VHDL Verification Methodology.
 - [**VUnit**][vunit] - Unit testing framework for VHDL.

Both dependencies are available as GitHub repositories and are linked to
PoC as git submodules into the [`<PoCRoot>\lib\`][lib] directory.

 [osvvm]:	https://github.com/JimLewis/OSVVM
 [vunit]:	https://github.com/VUnit/vunit


## 5 Configuring PoC on a Local System (Stand Alone)

To explore PoC's full potential, it's required to configure some paths and
synthesis or simulation tool chains. The following commands start a guided
configuration process. Please follow the instructions. It's possible to
relaunch the process at every time, for example to register new tools or to
update tool versions. See the [Configuration][wiki:configuration] wiki page
for more details.

> All Windows command line instructions are intended for **Windows PowerShell**,
> if not marked otherwise. So executing the following instructions in Windows
> Command Prompt (`cmd.exe`) won't function or result in errors! See the
> [Requirements][wiki:requirements] wiki page on where to download or update
> PowerShell.

Run the following command line instructions to configure PoC on your local system.

```PowerShell
cd <PoCRoot>
.\poc.ps1 --configure
```

**Note:** The configuration process can be re-run at every time to add, remove
or update choices made.


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
.\poc.ps1 --configure
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
done by invoking PoC's `Netlist.py` through one of the provided wrapper scripts:
netlist.[sh|ps1].

The following example compiles `PoC.xil.ChipScopeICON_1` from `<PoCRoot>\src\xil\xil_ChipScopeICON_1.xco`
for a Kintex-7 325T device into `<PoCRoot>/netlist/XC7K325T-2FFG900/xil/`.

```PowerShell
cd <PoCRoot>/netlist
.\netlist.ps1 --coregen PoC.xil.ChipScopeICON_1 --board KC705
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
 [temp]:				temp
 [tools]:				tools
 [ucf]:					ucf
 [xst]:					xst

 [wiki:download]:				https://github.com/VLSI-EDA/PoC/wiki/Download
 [wiki:requirements]:		https://github.com/VLSI-EDA/PoC/wiki/Requirements
 [wiki:configuration]:	https://github.com/VLSI-EDA/PoC/wiki/Configuration
 [wiki:integration]:		https://github.com/VLSI-EDA/PoC/wiki/Integration

 [wiki:subnamespacetree]:	https://github.com/VLSI-EDA/PoC/wiki/SubnamespaceTree
