
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


.. rubric:: The PoC-Library has the following goals:

* independenability
* generics implementations
* efficient, resource 'schonend' and fast implementations
* optimized for several target architectures if suitable


.. rubric:: PoC's independancies:

* platform independenability on the host system: Darwin, Linux or Windows
* target independenability on the device target: ASIC or FPGA
* vendor independenability on the device vendor: Altera, Lattice, Xilinx, ...
* tool chain independenability for simulation and synthesis tool chains


.. toctree::
   :hidden:
   
   WhyShouldIUsePoC
   SupportedToolChains
   WhoUsesPoC
   ThirdParty
