
What is PoC?
############

PoC - "Pile of Cores" provides implementations for often required hardware
functions such as Arithmetic Units, Caches, Clock-Domain-Crossing Circuits,
FIFOs, RAM wrappers, and I/O Controllers. The hardware modules are typically
provided as VHDL or Verilog source code, so it can be easily re-used in a
variety of hardware designs.

All hardware modules use a common set of VHDL packages to share new VHDL types,
sub-programs and constants. Additionally, a set of simulation helper packages
eases the writing of testbenches. Because PoC hosts a huge amount of IP cores,
all cores are grouped into sub-namespaces to build a better hierachy.

Various simulation and synthesis tool chains are supported to interoperate with
PoC. To generalize all supported free and commercial vendor tool chains, PoC is
shipped with a Python based Infrastruture to offer a command line based frontend.


.. rubric:: The PoC-Library pursues the following five goals:

* independence in the platform, target, vendor and tool chain
* generic, efficient, resource sparing and fast implementations of IP cores
* optimized for several device architectures, if suitable
* supportive scripts to ease the IP core handling with all supported
  vendor tools on all listed operating systems
* ship all IP cores with testbenches for local and online verification

.. rubric:: In detail the PoC-Library is:

* synthesizable for ASIC and FPGA devices, e.g. from Altera, Lattice, Xilinx, ...,
* supports a wide range of simulation and synthesis tool chains, and is
* executable on several host platforms: Darwin, Linux or Windows.

This is achieved by using generic HDL descriptions, which work with most
synthesis and simulation tools mentioned above. If this is not the case, then
PoC uses vendor or tool dependent work-arounds. These work-arounds can be
different implementations switched by VHDL `generate` statements as well as
different source files containing modified implementations.

One special feature of PoC is it, that the user has not to take care of such
implementation switchings. PoC's IP cores decide on their own what's the *best*
implementation for the chosen target platform. For this feature, PoC implements
a configuration package, which accepts a well-known development board name or a
target device string. For example a FPGA device string is decoded into: vendor,
device, generation, family, subtype, speed grade, pin count, etc. Out of these
information, the PoC component can for example implement a vendor specific
carry-chain description to speed up an algorithm or group computation units to
effectively use 6-input LUTs.


.. toctree::
   :hidden:

   History
   SupportedToolChains
   WhyShouldIUsePoC
   WhoUsesPoC
