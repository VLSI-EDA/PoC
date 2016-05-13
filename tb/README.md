# PoC Testbenches

**The PoC-Library** can launch manual, half-automated and fully automated
testbenches. The testbench can be run in command line or GUI mode. If available,
the used simulator is launched with pre-configured waveform files. This can be
done by invoking PoC's frontend script: `poc.[sh|ps1]` and passing the simulator
command plus the entity to simulate.

PoC supports the following simulators:

 -  Cocotb + Mentor Graphics QuestaSim
 -  GHDL + GTKWave
 -  Mentor Graphics ModellSim (vSim)
 -  Mentor Graphics QuestaSim (vSim)
 -  Mentor Graphics ModellSim Altera Edition (vSim)
 -  Xilinx ISE Simulator 14.7 (iSim)
 -  Xilinx Vivado Simulator (xSim)

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
> .\poc.ps1 configure
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
`arith_prng.vhdl` (Pseudo Random Number Generator - PRNG). The VHDL file is located at
`<PoCRoot>/src/arith/` and virtually a member in the `PoC.arith` namespace. So the module can be
identified by an unique name: `PoC.arith.prng`, which is passed to the testbench script.

##### Example 1:

```Bash
cd <PoCRoot>
./poc.sh isim PoC.arith.prng
```

The CLI option switch `isim` chooses *ISE Simulator* (iSim) as the simulator and passes the module name as parameter
to the tool. All required source file are gathered and "fused" to an executable. Afterwards this
executable is launched in CLI mode and it's outputs are displayed in console:

[![PowerShell console output for PoC.arith.prng][arith_prng_tb]][arith_prng_tb]
(click to enlarge)

 [arith_prng_tb]: https://github.com/VLSI-EDA/PoC/wiki/images/arith_prng_tb.png

##### Example 2:

Passing a second option `-g` to the testbench tool, opens the testbench in GUI-mode. If a waveform configuration file is present (e.g. \*.wcfg files for iSim), then it is preloaded into the simulator's GUI.

```PowerShell
cd <PoCRoot>
.\poc.ps1 isim PoC.arith.prng -g
```

See the red frame in the lower left corner: If everything was ok: `SIMULATION RESULT = PASSED` is
printed onto the simulator console.

[![iSim GUI for PoC.arith.prng][arith_prng_tb_isim]][arith_prng_tb_isim]
(click to enlarge)

 [arith_prng_tb_isim]: https://github.com/VLSI-EDA/PoC/wiki/images/arith_prng_tb_isim.png


## Running a Testbench

A testbench is supervised by PoC's `<PoCRoot>\py\PoC.py`, which offers a consistent interface to all
simulators. Unfortunately, every platform has it's specialties, so a wrapper script is needed as abstraction
from the host's system. On Windows it's `<PoCRoot>\poc.ps1`, on Linux and Darwin it's `<PoCRoot>/poc.sh`.

##### Darwin (Bash):

```Bash
cd <PoCRoot>
./poc.sh <common options> <simulator> <module> <simulator options>
```

##### Linux (Bash):

```Bash
cd <PoCRoot>
./poc.sh <common options> <simulator> <module> <simulator options>
```

##### Windows (PowerShell):

```PowerShell
cd <PoCRoot>
.\poc.ps1 <common options> <simulator> <module> <simulator options>
```

The service tool offers several common options:

    Common Option           Description
    ----------------------------------------------------------------------
    -h   --help             Print a short help
    -q                      Quiet-mode (print nothing)
    -v                      Print more messages
    -d                      Debug mode (print everything)
    -D                      Debug wrapper script

One of the following supported simulators can be choosen, if installed and configured in PoC:

    command                 Simulator
    ----------------------------------------------------------------------
    asim <module>           Active-HDL Simulator
    ghdl <module>           GHDL Simulator
    cocotb <module>         Cocotb simulation using QuestaSim Simulator
    vsim <module>           QuestaSim Simulator
    isim <module>           Xilinx ISE Simulator
    xsim <module>           Xilinx Vivado Simulator


## GHDL + GTKwave

The command is named `ghdl` followed by a list of PoC entities. The following options are supported
for GHDL:

    Option(s)                 Description
    ----------------------------------------------------------------------
         --board=<BOARD>      Specify a target board.
         --device=<DEVICE>    Specify a target device.
    -g   --gui                Start GTKwave, if installed.
                              Open *.gtkw, if available.
         --std=[87|93|02|08]  Select a VHDL standard. Default: 08

##### Example:

```PowerShell
cd <PoCRoot>
.\poc.ps1 -v ghdl PoC.arith.prng --board=Atlys -g
```

## Mentor Graphics QuestaSim

The command is named `vsim` followed by a list of PoC entities. The following options are supported
for ISE Simulator:

    Option(s)                 Description
    ----------------------------------------------------------------------
         --board=<BOARD>      Specify a target board.
         --device=<DEVICE>    Specify a target device.
    -g   --gui                Start in GUI-mode.
                              Open *.wdo, if available.
         --std=[87|93|02|08]  Select a VHDL standard. Default: 08


##### Example:

```PowerShell
cd <PoCRoot>
.\poc.ps1 -v vsim PoC.arith.prng --board=Atlys -g
```

## Xilinx ISE Simulator

The command is named `isim` followed by a list of PoC entities. The following options are supported
for ISE Simulator:

    Option(s)                 Description
    ----------------------------------------------------------------------
         --board=<BOARD>      Specify a target board.
         --device=<DEVICE>    Specify a target device.
    -g   --gui                Start in GUI-mode.
                              Open a *.wcfg, if available.

##### Example:

```PowerShell
cd <PoCRoot>
.\poc.ps1 -v isim PoC.arith.prng --board=Atlys -g
```

## Xilinx Vivado Simulator

The command is named `xsim` followed by a list of PoC entities. The following options are supported
for Vivado Simulator:

    Option(s)                 Description
    ----------------------------------------------------------------------
         --board=<BOARD>      Specify a target board.
         --device=<DEVICE>    Specify a target device.
    -g   --gui                Start in GUI-mode.
                              Open *.wcfg, if available.
         --std=[93|08]        Select a VHDL standard. Default: 93

##### Example:

```PowerShell
cd <PoCRoot>
.\poc.ps1 -v xsim PoC.arith.prng --board=Atlys -g
```


 [wiki_Requirements]:	https://github.com/VLSI-EDA/PoC/wiki/Requirements
 [wiki_Configuration]:	https://github.com/VLSI-EDA/PoC/wiki/Configuration
