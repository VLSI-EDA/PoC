Configuring PoC on a Local System (Stand Alone)
***********************************************

To explore PoC's full potential, it's required to configure some paths and synthesis or simulation tool chains. The following commands start a guided
configuration process. Please follow the instructions. It's possible to relaunch the process at every time, for example to register new tools or to update
tool versions. See the `Configuration] for more details.

  All Windows command line instructions are intended for **Windows PowerShell**, if not marked otherwise. So executing the following instructions in Windows
  Command Prompt (``cmd.exe``) won't function or result in errors! See the [Requirements] on where to download or update  PowerShell.

Run the following command line instructions to configure PoC on your local system. ::

    cd <PoCRoot>
    .\poc.ps1 configure

**Note:** The configuration process can be re-run at every time to add, remove or update choices made.

If you want to check your installation, you can run one of our testbenches as described in `tb/README.md]


Table of Content:
--------------------------------------------------------------------------------
 1. [Configuring PoC on a Local System](#1-configuring-poc-on-a-local-system)  
 	[1.1 Xilinx ISE](#11-xilinx-ise)  
 	[1.2 Xilinx LabTools](#12-xilinx-labtools)  
 	[1.3 Xilinx Vivado](#13-xilinx-vivado)  
 	[1.4 Xilinx Hardware Server](#14-xilinx-hardware-server)  
 	[1.5 Mentor Graphics QuestaSim](#15-mentor-graphics-questasim)  
 	[1.6 GHDL](#16-ghdl)  
 	[1.7 GTKwave](#17-gtkwave)  
 2. [Creating PoC's my_config and my_project Files](#2-creating-pocs-my-config-and-my-project-files)

--------------------------------------------------------------------------------

> All Windows command line instructions are intended for **Windows PowerShell**, if not marked otherwise. So executing the following instructions in Windows Command Prompt (`cmd.exe`) won't function or result in errors! See the [Requirements](Requirements) wiki page on where to download or update PowerShell.

## 1. Configuring PoC on a Local System

To explore PoC's full potential, it's required to configure some paths
and synthesis or simulation tool chains.

##### Linux:

```Bash
cd <ProjectRoot>
cd lib/PoC/
./poc.ps1 configure
```

##### Windows (PowerShell):

```PowerShell
cd <ProjectRoot>
cd lib\PoC\
.\poc.ps1 configure
```

Follow the instructions on the screen.

#### Introduction screen:

    ================================================================================
                       The PoC-Library - Repository Service Tool
    ================================================================================
    
    Explanation of abbreviations:
      y - yes
      n - no
      p - pass (jump to next question)
    Upper case means default value

#### 1.1 Xilinx ISE

If an Xilinx ISE environment is available and shall be configured in PoC, then answer the
following questions:

    Is Xilinx ISE installed on your system? [Y/n/p]: y
    Xilinx Installation Directory [C:\Xilinx]: C:\Xilinx
    Xilinx ISE Version Number [14.7]: 14.7

#### 1.2 Xilinx LabTools

    Is Xilinx LabTools installed on your system? [Y/n/p]: n

#### 1.3 Xilinx Vivado

    Is Xilinx Vivado installed on your system? [Y/n/p]: y
    Xilinx Installation Directory [C:\Xilinx]: C:\Xilinx
    Xilinx Vivado Version Number [2014.4]: 2015.2

#### 1.4 Xilinx Hardware Server

    Is Xilinx HardwareServer installed on your system? [Y/n/p]: n

#### 1.5 Mentor Graphics QuestaSim

    Is Questa-SIM installed on your system? [Y/n/p]: y
    Questa-SIM Installation Directory [C:\Mentor\QuestaSim64\10.2c]: C:\Mentor\QuestaSim64\10.3
    Questa-SIM Version Number [10.2c]: 10.3

#### 1.6 GHDL

    Is GHDL installed on your system? [Y/n/p]: y
    GHDL Installation Directory [C:\Program Files (x86)\GHDL]: C:\Tools\GHDL\0.33dev
    GHDL Version Number [0.31]: 0.33

#### 1.7 GTKwave

    Is GTKWave installed on your system? [Y/n/p]: y
    GTKWave Installation Directory [C:\Program Files (x86)\GTKWave]: C:\Tools\GTKWave\3.3.66
    GTKWave Version Number [3.3.61]: 3.3.66


## 2. Creating PoC's my_config and my_project Files

The PoC-Library needs two VHDL files for it's configuration. These files are used to determine the most
suitable implementation depending on the provided platform information. These files are also used to select
appropiate work arounds.

 1. The **my_config** file can easily be created from a template file provided by PoC in
    `<PoCRoot>\src\common\my_config.vhdl.template`.

    The file should to be copyed into a projects source directory and rename into `my_config.vhdl`. This file
    should be included into version control systems and shared with other systems. my_config.vhdl defines three global constants, which need to be adjusted:

    ```VHDL
    constant MY_BOARD   : string   := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
    constant MY_DEVICE  : string   := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3
    constant MY_VERBOSE : boolean  := FALSE;         -- activate detailed report statements in functions and procedures
    ```

    The easiest way is to define a board name and set `MY_DEVICE` to `None`. So the device name is infered
    from the board information stored in `<PoCRoot>\src\common\board.vhdl`. If the requested board is not known
    to PoC or it's custom made, then set `MY_BOARD` to `Custom` and `MY_DEVICE` to the full FPGA device string.

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

 2. The **my_project** file can also be created from a template provided by PoC in
    `<PoCRoot>\src\common\my_project.vhdl.template`.
    
    The file should to be copyed into a projects source directory and rename into `my_project.vhdl`. This
    file **must not** be included into version control systems - it's private to a host computer.
    my_project.vhdl defines two global constants, which need to be adjusted:

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

