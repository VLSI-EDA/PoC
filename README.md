The PoC Library
================================================================================

PoC - “Pile of Cores” provides implementations for often required hardware
functions such as FIFOs, RAM wrapper, and ALUs. The hardware modules are
typically provided as VHDL or Verilog source code, so it can be easily re-used
in a variety of hardware designs.

## Table of Content:
 1. [Overview](#1-overview)
 2. [Download](#2-download)
 3. [Requirements](#3-requirements)
	- [Common Requirements](#common-requirements)
	- [Optional Tools](#optional-tools)
 4. [Configure PoC on a Local System](#4-configure-poc-on-a-local-system)
 5. [Integrating PoC into projects](#5-integrating-poc-into-projects)
 6. [Using PoC-Library](#6-using-poc-library)
 7. [Updating PoC-Library](#7-updating-picoblaze-library)

------

> All Windows command line instructions are intended for **Windows PowerShell**, if not marked otherwise. So executing the following instructions in Windows Command Prompt (`cmd.exe`) won't function or result in errors! PowerShell is shipped with Windows since Vista. See the [requirements](Requirements) wiki page on where to download or update PowerShell.

## 1 Overview




## 2 Download

The PicoBlaze-Library can be downloaded as a [zip-file][download] or
cloned with `git clone` from GitHub. For SSH protocol use the URL `ssh://git@github.com:VLSI-EDA/PoC.git` or the command line instruction:

    cd <GitRoot>
    git clone --recursive git@github.com:VLSI-EDA/PoC.git PoC
    cd PoC
    git remote rename origin github

**Note:** The option `--recursive` performs a recursive clone operation for all integrated [git submodules][git_submod]. An additional `git submodule init` and `git submodule update` is not needed anymore. 

The library is meant to be included into another git repository as a git submodule. This can be achieved with the following instructions:

    cd <ProjectRoot>
    mkdir lib -ErrorAction SilentlyContinue; cd lib
    git submodule add git@github.com:VLSI-EDA/PoC.git PoC
    cd PoC
    git remote rename origin github
    cd ..\..
    git add .gitmodules lib\PoC
    git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."


A detailed explanation and full command line examples for Windows and Linux are provided on the [Download](Download) wiki page.

 [download]: https://github.com/VLSI-EDA/PoC/archive/master.zip

## 3 Requirements

##### Common Requirements

A VHDL synthesis tool chain is need to compile all source files into a FPGA configuration.  If needed, a simulation tool chain can be used to simulate and debug the modules and packages.

See the [requirements](Requirements#common-requirements) wiki page for more details.  


##### Optional Tools

There are several optional tools, which ease the use of this library.

See the [optional tools](Requirements#optional-tools) wiki page for more details.

## 4 Configure PoC on a Local System


## 5 Integrating PoC into projects

To run PoC's automated testbenches or use the netlist compilaltion scripts of PoC, it's required to configure a synthesis and simulation tool chain.

    cd <ProjectRoot>
    cd lib\PoC\
    .\poc.ps1 --configure

TODO: wiki page link, step-by-step config flow, images

### 5.1 Adding the library as git submodules

The PoC-Library is meant to be included in other project or repos as a submodule. Therefore it's recommended to create a library folder and add the PoC-Library and it's dependencies as git submodules.

The following command line instructions will create a library folder `lib/` and clone all depenencies
as git [submodules][git_submod] into subfolders.

    cd <ProjectRoot>
    mkdir lib -ErrorAction SilentlyContinue; cd lib
    git submodule add git@github.com:VLSI-EDA/PoC.git PoC
    cd PoC
    git remote rename origin github
    cd ..\..
    git add .gitmodules lib\PoC
    git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."

[git_submod]: http://git-scm.com/book/en/v2/Git-Tools-Submodules

### 5.2 Configuring PoC on a Local System

To run PoC's automated testbenches or use the netlist compilaltion scripts of PoC, it's required to configure a synthesis and simulation tool chain.

    cd <ProjectRoot>
    cd lib\PoC\
    .\poc.ps1 --configure

TODO: wiki page link, step-by-step config flow, images

### 5.3 Compiling shipped Xilinx IPCores (*.xco files) to netlists

The PoC-Library is shipped with some pre-configured IPCores from Xilinx. These IPCores are shipped as \*.xco files and need to be compiled to netlists (\*.ngc files) and there auxillary
files (\*.ncf files; \*.vhdl files; ...). This can be done by invoking PoC's `Netlist.py` through one of the
provided wrapper scripts: netlist.[sh|ps1].

**Example:** Compiling all needed IPCores from PoC for a KC705 board:

    cd <ProjectRoot>
    cd lib\PoC\netlist
    foreach ($i in 1..15) {
      .\netlist.ps1 --coregen PoC.xil.ChipScopeICON_$i --board KC705
    }


## 6 Using the PoC-Library


### 6.1 Standalone

### 6.2 In Altera Quartus II

### 6.3 In GHDL

### 6.4 In ModelSim/QuestaSim

### 6.4 In Xilinx ISE (XST and iSim)

### 6.5 In Xilinx Vivado (Synth and xSim)


## 6 Configuring a System-on-FPGA with the library



## 7 Updating PoC-Library

