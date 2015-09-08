# The PoC-Library

PoC - "Pile of Cores" provides implementations for often required hardware
functions such as FIFOs, RAM wrapper, and ALUs. The hardware modules are
typically provided as VHDL or Verilog source code, so it can be easily re-used
in a variety of hardware designs.

Table of Content:
--------------------------------------------------------------------------------
 1. [Overview](#1-overview)
 2. [Download](#2-download)
 3. [Requirements](#3-requirements)
 4. [Configure PoC on a Local System](#4-configure-poc-on-a-local-system)
 5. [Integrating PoC into projects](#5-integrating-poc-into-projects)
 6. [Using PoC](#6-using-poc)
 7. [Updating PoC](#7-updating-poc)

--------------------------------------------------------------------------------

## 1 Overview

TODO TODO TODO

Other repositories: [PoC-Examples][poc_ex]

 [poc_ex]:  https://github.com/VLSI-EDA/PoC-Examples


## 2 Download

**The PoC-Library** can be downloaded as a [zip-file][download] (latest 'master' branch) or
cloned with `git clone` from GitHub. GitHub offers HTTPS and SSH as transfer protocols.
See the [Download][wiki-download] wiki page for more details.

For SSH protocol use the URL `ssh://git@github.com:VLSI-EDA/PoC.git` or command
line instruction:

    cd <GitRoot>
    git clone ssh://git@github.com:VLSI-EDA/PoC.git PoC

For HTTPS protocol use the URL `https://github.com/VLSI-EDA/PoC.git` or command
line instruction:

    cd <GitRoot>
    git clone https://github.com/VLSI-EDA/PoC.git PoC

 [download]: https://github.com/VLSI-EDA/PoC/archive/master.zip


## 3 Requirements

The PoC-Library comes with some scripts to ease most of the common tasks, like
running testbenches or generating IP cores. We choose to use Python as a platform
independent scripting environment. All Python scripts are wrapped in PowerShell
or Bash scripts, to hide some platform specifics of Windows or Linux. See the
[Requirements][wiki-requirements] wiki page for more details and download sources.

#### Common requirements:

 - Programming languages and runtimes:
	- [Python 3][python] (&ge; 3.4):
	     - [colorama][colorama]
 - Synthesis tool chains:
     - Xilinx ISE 14.7 or
     - Xilinx Vivado 2014.x or
     - Altera Quartus II 13.x
 - Simulation tool chains:
     - Xilinx ISE Simulator 14.7 or
     - Xilinx Vivado Simulator 2014.x or
     - Mentor Graphics ModelSim Altera Edition or
     - Mentor Graphics QuestaSim or
     - [GHDL][ghdl] and [GTKWave][gtkwave]

 [python]:		https://www.python.org/downloads/
 [colorama]:	https://pypi.python.org/pypi/colorama
 [ghdl]:		https://sourceforge.net/projects/ghdl-updates/
 [gtkwave]:		http://gtkwave.sourceforge.net/

#### Linux specific requirements:
 
 - Debian specific:
	- bash is configured as `/bin/sh` ([read more](https://wiki.debian.org/DashAsBinSh))  
      `dpkg-reconfigure dash`
 
#### Windows specific requirements:

 - PowerShell 4.0 ([Windows Management Framework 4.0][wmf40])
    - Allow local script execution ([read more][execpol])  
      `PS> Set-ExecutionPolicy RemoteSigned`
    - PowerShell Community Extensions 3.2 ([pscx.codeplex.com][pscx])

 [wmf40]:   http://www.microsoft.com/en-US/download/details.aspx?id=40855
 [execpol]: https://technet.microsoft.com/en-us/library/hh849812.aspx
 [pscx]:    http://pscx.codeplex.com/


## 4 Configure PoC on a Local System

To explore PoC's full potential, it's required to configure some paths and
synthesis or simulation tool chains. The following commands start a guided
configuration process. Please follow the instructions. It's possible to
relaunch the process at every time, for example to register new tools or to
update tool versions. See the [Configuration][wiki-configuration] wiki page
for more details.

##### Linux:

Run the following command line instructions to configure PoC on your local system.

```Bash
cd <PoCRoot>
./poc.sh --configure
```

##### Windows (PowerShell):

> All Windows command line instructions are intended for **Windows PowerShell**,
> if not marked otherwise. So executing the following instructions in Windows
> Command Prompt (`cmd.exe`) won't function or result in errors! See the
> [Requirements][wiki-requirements] wiki page on where to download or update
> PowerShell.

```PowerShell
cd <PoCRoot>
.\poc.ps1 --configure
```

## 5 Integrating PoC into projects

**The PoC-Library** is meant to be integrated into HDL projects. Therefore it's
recommended to create a library folder and add the PoC-Library as a git submodule.
After the repository linking is done, some short configuration steps are required
to setup paths and tool chains. The following command line instructions show a
short example on how to integrate PoC. A detailed list of steps can be found on the
[Integration][wiki-integration] wiki page.

#### 5.1 Adding the Library as a git submodule

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

#### 5.2 Configuring PoC on a Local System

```PowerShell
cd <ProjectRoot>
cd lib\PoC\
.\poc.ps1 --configure
```

#### 5.3 Creating PoC's my_config and my_project Files

The PoC-Library needs two VHDL files for it's configuration. These files are used to
determine the most suitable implementation depending on the provided platform information.
Copy these two template files into your project's source folder. Rename these files to
*.vhdl and configure the constants in these files.  

```PowerShell
cd <ProjectRoot>
cp lib\src\common\my_config.vhdl.template src\common\my_config.vhdl
cp lib\src\common\my_project.vhdl.template src\common\my_project.vhdl
```

#### 5.4 Compile shipped Xilinx IP cores (*.xco files) to Netlists

The PoC-Library are shipped with some pre-configured IP cores from Xilinx. These
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

## 6 Using PoC

TODO TODO TODO

#### 6.1 Standalone

#### 6.2 In Altera Quartus II

#### 6.3 In GHDL

#### 6.4 In ModelSim/QuestaSim

#### 6.4 In Xilinx ISE (XST and iSim)

#### 6.5 In Xilinx Vivado (Synth and xSim)

## 7 Updating PoC


 [wiki-download]:		https://github.com/VLSI-EDA/PoC/wiki/Download
 [wiki-requirements]:	https://github.com/VLSI-EDA/PoC/wiki/Requirements
 [wiki-configuration]:	https://github.com/VLSI-EDA/PoC/wiki/Configuration
 [wiki-integration]:	https://github.com/VLSI-EDA/PoC/wiki/Integration


