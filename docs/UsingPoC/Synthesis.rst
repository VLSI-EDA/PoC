# Generated Netlists from PoC and IP Core Generators

**The PoC-Library** supports the generation of netlists from pre-configured
vendor IP cores (e.g. Xilinx Core Generator) or from bundled and pre-configured
PoC entities. This can be done by invoking PoC's Service Tool through the wrapper
script: `poc.[sh|ps1]`.

PoC supports the following tools:

 -  Altera Quartus II / Quartus Prime
 -  Lattice Diamond LSE
 -  Xilinx Core Generator 14.7 (corgen)
 -  Xilinx Synthesis Tool 14.7 (xst)

Planned tool support:

 -  Altera MegaFunction Wizard
 -  Xilinx Vivado Synth
 -  Xilinx Vivado IP Core Catalog

> All Windows command line instructions are intended for **Windows PowerShell**,
> if not marked otherwise. So executing the following instructions in Windows
> Command Prompt (`cmd.exe`) won't function or result in errors! See the
> [Requirements][wiki:requirements] wiki page on where to download or update
> PowerShell.


## 1 Common Explanations

A netlist is always compiled for a specific platform. In case of an FPGA it's
the exact device name. The name can be passed by `--device=<DEVICE>` command
line option to the script. An alternative is the `--board=<BOARD>` option. For
a list of well-known board names, PoC knows the soldered FPGA device.

The service tool offers several common options:

    Common Option           Description
    ----------------------------------------------------------------------
    -h   --help             Print a short help
    -q                      Quiet-mode (print nothing)
    -v                      Print more messages
    -d                      Debug mode (print everything)
    -D                      Debug wrapper script


## 2 Compiling pre-configured Xilinx IP Cores (*.xco files) to Netlists

**The PoC-Library** is shipped with some pre-configured IP cores from Xilinx.
These IP cores are shipped as \*.xco files and need to be compiled to netlists
(\*.ngc files) and there auxillary files (\*.ncf files; \*.vhdl files; ...). IP
core configuration files (e.g. *.xco) are stored as regular source files in the
`<PoCRoot>\src` directory.

```PowerShell
.\poc.ps1 [-q] [-v] [-d] coregen <PoC-Entity> [--device=<DEVICE>|--board=<BOARD>]
```

#### Use Case - Compiling all ChipScopeICON IP Cores

PoC has an abstraction layer [`PoC.xil.ChipScopeICON`][xil_ChipScopeICON] to
abstract all possible Chipscope Integrated Controller (ICON) cores
configurations in one VHDL module. An ICON can be configured with 1 to 15
ChipScope control ports. To use the abstraction layer it's required to
pre-compile all 15 IP core variations.

The following example compiles the first IP core with 1 port for a Kintex-7
325T as soldered onto a KC705 board. The resulting netlist and auxillary files
are copied to `<PoCRoot>/netlist/XC7K325T-2FFG900/xil/`. The Xilinx ISE tool
flow requires an extension IP core search directory for *XST* and *Translate*
(`-sd` option).

```PowerShell
cd <PoCRoot>
.\poc.ps1 coregen PoC.xil.ChipScopeICON_1 --board=KC705
```

The compilation can be automated in a for-each loop for all IP cores:

```PowerShell
cd <PoCRoot>
foreach ($i in 1..15)
{	.\poc.ps1 coregen PoC.xil.ChipScopeICON_$_ --board=KC705
}
```


## 3 Compiling pre-configured PoC IP Cores (bundle of VHDL files) to Netlists

*Documentation is still incomplete*

The IP core filelist file (*.files) and the XST option file (*.xst) are stored
in the `<PoCRoot>\xst` directory.

```PowerShell
.\poc.ps1 [-q] [-v] [-d] xst <PoC-Entity> [--device=<DEVICE>|--board=<BOARD>]
```

#### Use Case - Compiling a Gigabit Ethernet UDP/IP Stack for a KC705 board

`PoC.net.stack.UDPv4`

*Documentation is still incomplete*

The resulting netlist and auxillary files
are copied to `<PoCRoot>/netlist/XC7K325T-2FFG900/net/stack`. The Xilinx ISE tool
flow requires an extension IP core search directory for *XST* and *Translate*
(`-sd` option).

 [xil_ChipScopeICON]:		../src/xil/xil_ChipScopeICON.vhdl