This library is published and maintained by **Chair for VLSI Design, Diagnostics
and Architecture** - Faculty of Computer Science, Technische Universität Dresden,
Germany |br|
`http://tu-dresden.de/inf/vlsi-eda <http://tu-dresden.de/inf/vlsi-eda>`_

.. image:: _static/images/logo_tud.jpg
   :scale: 10
   :alt: Logo: Technische Universität Dresden

--------------------------------------------------------------------------------

The PoC-Library Documentation
#############################

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


News
****

13.05.2016 - PoC 1.0.0 was release.
===================================

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor
sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet


.. toctree::
   :hidden:
    
   WhatIsPoC/index
   QuickStart/index
   UsingPoC/index
   References/index
   PoC/index
   References/Licenses/License
   GetInvolved/index

