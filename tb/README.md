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

Planned tool support:

 -  Aldec Rivera Pro

> All Windows command line instructions are intended for **Windows PowerShell**,
> if not marked otherwise. So executing the following instructions in Windows
> Command Prompt (`cmd.exe`) won't function or result in errors! See the
> [Requirements][wiki:requirements] wiki page on where to download or update
> PowerShell.


