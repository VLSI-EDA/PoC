The PoC Library
================================================================================

PoC - “Pile of Cores” provides implementations for often required hardware
functions such as FIFOs, RAM wrapper, and ALUs. The hardware modules are
typically provided as VHDL or Verilog source code, so it can be easily re-used
in a variety of hardware designs.

Table of Content:
================================================================================
 1. Overview
 2. Download
 3. Requirements 
 4. Configure PoC on a local system  
 5. Integrating PoC into projects  
 6. Using PoC  
 7. Updating PoC


1 Overview
================================================================================



2 Download
================================================================================
The PoC Library can be [downloaded][21] as a zip-file (master branch) or cloned
with git from GitHub. GitHub offers HTTPS and SSH as transfer protocols. Here are
the repository URLs:

    https:  https://github.com/VLSI-EDA/PoC.git  
    ssh:    ssh://git@github.com:VLSI-EDA/PoC.git

Cloning PoC with git command line tools:

    git clone ssh://git@github.com:VLSI-EDA/PoC.git PoC

3 Requirements
================================================================================
### Common requirements:

 - Python 3.4
     - colorama ([pypi.python.org/pypi/colorama][301])
 - Syntheis tool chains:
     - Xilinx ISE 14.7 or
     - Xilinx Vivado 2014.x or
     - Altera Quartus II 13.x
 - Simulation tool chains:
     - Xilinx ISE Simulator 14.7 or
     - Xilinx Vivado Simulator 2014.x or
     - Menthor Graphics ModelSim Altera Edition or
     - Menthor Graphics QuestaSim or
     - [GHDL][302] and [GTKWave][303]

### Linux specific requirements:

 
### Windows specific requirements:

 - PowerShell 4.0 ([Windows Management Framework 4.0][321])
    - Local script execution is allowed (execution policy is set to 'RemoteSigned' - [read more][322])    
    - PowerShell Community Extensions 3.2 ([pscx.codeplex.com][323])


4 Configure PoC on a local system
================================================================================

### 4.1 Linux system

Run the following command line instructions to configure PoC on your local system.

    cd <PoCRoot>
    ./poc.sh --configure


### 4.2 Windows system

All Windows command line instructions are build for PowerShell. So executing the following instructions in `cmd.exe` won't function or result in errors! PowerShell is shipped with Windows since Vista.  

    cd <PoCRoot>
    .\poc.ps1 --configure

5 Integrating PoC into projects
================================================================================

### 5.1 Adding PoC as a git submodule

The following command line instructions will create the folder `lib/PoC` and clone
the PoC Library as a [submodule][511] into that folder.

    cd <ProjectRoot>
    mkdir -p lib/PoC
    git submodule add ssh://git@github.com:VLSI-EDA/PoC.git lib/PoC
    git add .gitmodules lib/PoC
    git commit -m "Added new git submodule PoC in 'lib/PoC' (PoC Library)."

### 5.2 ...


6 Using PoC
================================================================================

### 6.1 Standalone

### 6.2 In Altera Quartus II

### 6.3 In GHDL

### 6.4 In ModelSim/QuestaSim

### 6.4 In Xilinx ISE (XST and iSim)

### 6.5 In Xilinx Vivado (Synth and xSim)

7 Updating PoC
================================================================================



 [21]: https://github.com/VLSI-EDA/PoC/archive/master.zip
 [301]: https://pypi.python.org/pypi/colorama
 [302]: https://sourceforge.net/projects/ghdl-updates/
 [303]: http://gtkwave.sourceforge.net/
 [321]: http://www.microsoft.com/en-US/download/details.aspx?id=40855
 [322]: https://technet.microsoft.com/en-us/library/hh849812.aspx
 [323]: http://pscx.codeplex.com/
 [511]: http://git-scm.com/book/en/v2/Git-Tools-Submodules
