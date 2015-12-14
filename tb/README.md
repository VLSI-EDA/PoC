# PoC Testbenches

**The PoC-Library** can launch manual, half-automated and fully automated
testbenches. The testbench can be run in command line or GUI mode. If available,
the used simulator is launched with pre-configured waveform files. This can be
done by invoking PoC's `Testbench.py` through one of the provided wrapper
scripts: testbench.[sh|ps1].

PoC supports the following simulators:

 -  Xilinx ISE Simulator 14.7 (iSim)
 -  Xilinx Vivado Simulator (xSim)
 -  Mentor Graphics ModellSim (vSim)
 -  Mentor Graphics QuestaSim (vSim)
 -  ModellSim Altera Edition (vSim)
 -  GHDL + GTKWave

> All Windows command line instructions are intended for **Windows PowerShell**,
> if not marked otherwise. So executing the following instructions in Windows
> Command Prompt (`cmd.exe`) won't function or result in errors! See the
> [Requirements][wiki_Requirements] wiki page on where to download or update PowerShell.
> 
> **Is PoC already configured on the system?** If not, run the following
> configuration step, to tell PoC which tool chains are installed and where.
> Follow the instructions on the screen. See the [Configuration][wiki_Configuration]
> wiki page for more details.
> ```PowerShell
> cd <PoCRoot>
> .\poc.ps1 --configure
> ```


Table of Content:
--------------------------------------------------------------------------------
 - [Quick Example](#quick-example)
 - [Running a Testbench](#running-a-testbench)
 - [Xilinx ISE Simulator](#xilinx-ise-simulator)
 - [Xilinx Vivado Simulator](#xilinx-vivado-simulator)
 - [Mentor Graphics QuestaSim](#mentor-graphics-questasim)
 - [GHDL + GTKwave](#ghdl--gtkwave)
 - [Debugging](#debugging)

--------------------------------------------------------------------------------


## Quick Example

The following quick example uses the Xilinx ISE Simulator to compile a testbench for the module
`arith_prng.vhdl` (Pseudo Random Number Generator - prng). The VHDL file is located at
`<PoCRoot>/src/arith/` and virtually a member in the `PoC.arith` namespace. So the module can be
identified by an unique name: `PoC.arith.prng`, which is passed to the testbench script.

##### Example 1:

```Bash
cd <PoCRoot>\tb
.\testbench.ps1 --isim PoC.arith.prng
```

The CLI option switch `--isim` chooses iSim as the simulator and passes the module name as parameter
to the testbench tool. All required source file are gathered and fused to an executable. Afterwards this
executable is launched in CLI mode and it's outputs are displayed in console:

[![PowerShell console output for PoC.arith.prng][arith_prng_tb]][arith_prng_tb]
(click to enlarge)

 [arith_prng_tb]: https://github.com/VLSI-EDA/PoC/wiki/images/arith_prng_tb.png

##### Example 2:

Passing a second option `-g` to the testbench tool, opens the testbench in GUI-mode. If a waveform configuration file is present (e.g. \*.wcfg files for iSim), then it is preloaded into the simulator's GUI.

```PowerShell
cd <PoCRoot>\tb
.\testbench.ps1 --isim PoC.arith.prng -g
```

See the red frame in the lower left corner: If everything was ok: `SIMULATION RESULT = PASSED` is
printed onto the simulator console.

[![iSim GUI for PoC.arith.prng][arith_prng_tb_isim]][arith_prng_tb_isim]
(click to enlarge)

 [arith_prng_tb_isim]: https://github.com/VLSI-EDA/PoC/wiki/images/arith_prng_tb_isim.png

## Running a Testbench

A testbench is supervised by PoC's `<PoCRoot>\py\Testbench.py`, which offers a consistent interface to all
simulators. Unfortunately, every system has it's specialties, so a wrapper script is needed as abstraction
from the host's system. On Windows it's `<PoCRoot>\tb\testbench.ps1`, on Linux `<PoCRoot>/tb/testbench.sh`.

##### Linux:

```Bash
cd <PoCRoot>/tb
./testbench.sh <options> <simulator> <module>
```

##### Windows (PowerShell):

```PowerShell
cd <PoCRoot>\tb
.\testbench.ps1 <options> <simulator> <module>
```

The testbench supervisor offers several common options, which are listed below:

    Option(s)                 Description
    ----------------------------------------------------------------------
    -h   --help               Print a help page
    -l                        Show log messages
    -v                        Print more messages
    -d                        Debug mode (print everything)
    -D                        Debug wrapper script
    -q                        Quiet-mode (print nothing)
    -r                        Show report

One of the following supported simulators can be choosen, if installed and configured in PoC:

    Switch                    Simulator
    ----------------------------------------------------------------------
         --isim <module>      Xilinx ISE Simulator
         --xsim <module>      Xilinx Vivado Simulator
         --vsim <module>      QuestaSim Simulator
         --ghdl <module>      GHDL Simulator


## Xilinx ISE Simulator

    Option(s)                 Description
    ----------------------------------------------------------------------
         --isim <module>      Use Xilinx ISE Simulator
    -g   --gui                Start in GUI-mode.
                              Open *.wcfg, if available.

##### Example:

```PowerShell
cd <PoCRoot>\tb
.\testbench.ps1 -g --isim PoC.arith.prng
```

## Xilinx Vivado Simulator

    Option(s)                 Description
    ----------------------------------------------------------------------
         --xsim <module>      Use Xilinx Vivado Simulator
    -g   --gui                Start in GUI-mode.
                              Open *.wcfg, if available.


##### Example:

```PowerShell
cd <PoCRoot>\tb
.\testbench.ps1 -g --xsim PoC.arith.prng
```

## Mentor Graphics QuestaSim

    Option(s)                 Description
    ----------------------------------------------------------------------
         --vsim <module>      Use QuestaSim Simulator
    -g   --gui                Start in GUI-mode.
                              Open *.wdo, if available.
         --std [87|93|02|08]  Select a VHDL standard


##### Example:

```PowerShell
cd <PoCRoot>\tb
.\testbench.ps1 -g --vsim PoC.arith.prng
```

## GHDL + GTKwave

    Option(s)                 Description
    ----------------------------------------------------------------------
         --ghdl <module>      Use GHDL Simulator
    -g   --gui                Start GTKwave, if installed.
                              Open *.gtkw, if available.
         --std [87|93|02|08]  Select a VHDL standard

##### Example:

```PowerShell
cd <PoCRoot>\tb
.\testbench.ps1 -g --ghdl PoC.arith.prng
```

 [wiki_Requirements]:	https://github.com/VLSI-EDA/PoC/wiki/Requirements
 [wiki_Configuration]:	https://github.com/VLSI-EDA/PoC/wiki/Configuration
