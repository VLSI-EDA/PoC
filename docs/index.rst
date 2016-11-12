This library is published and maintained by **Chair for VLSI Design, Diagnostics
and Architecture** - Faculty of Computer Science, Technische Universität Dresden,
Germany |br|
`https://tu-dresden.de/ing/informatik/ti/vlsi <https://tu-dresden.de/ing/informatik/ti/vlsi>`_

.. image:: _static/logos/tu-dresden.jpg
   :scale: 10
   :alt: Technische Universität Dresden

--------------------------------------------------------------------------------

.. image:: _static/logos/GitHub-Mark-32px.png
   :scale: 60
   :target: https://www.github.com/VLSI-EDA/PoC
   :alt: Source Code on GitHub
.. image:: https://landscape.io/github/VLSI-EDA/PoC/release/landscape.svg?style=flat
   :target: https://landscape.io/github/VLSI-EDA/PoC/release
   :alt: Code Health
.. image:: https://travis-ci.org/VLSI-EDA/PoC.svg?branch=release
   :target: https://travis-ci.org/VLSI-EDA/PoC
   :alt: Build Results
.. image:: https://badges.gitter.im/VLSI-EDA/PoC.svg
   :target: https://gitter.im/VLSI-EDA/PoC
   :alt: Join
.. image:: https://img.shields.io/github/tag/VLSI-EDA/PoC.svg?style=flat
   :alt: Latest tag
.. image:: https://img.shields.io/github/release/VLSI-EDA/PoC.svg?style=flat
   :target: https://github.com/VLSI-EDA/PoC/releases
   :alt: Latest release
.. image:: https://img.shields.io/github/license/VLSI-EDA/PoC.svg?style=flat
   :target: References/Licenses/License.html
   :alt: Apache License 2.0

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
shipped with a Python based infrastructure to offer a command line based frontend.


News
****

13.05.2016 - PoC 1.0.0 was released.
====================================

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor
sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet

Cite the PoC-Library
********************

The PoC-Library hosted at `GitHub.com <https://www.github.com>`_. Please use the
following `biblatex <https://www.ctan.org/pkg/biblatex>`_ entry to cite us:

.. code-block:: tex

   # BibLaTex example entry
   @online{poc,
     title={{PoC - Pile of Cores}},
     author={{Chair of VLSI Design, Diagnostics and Architecture}},
     organization={{Technische Universität Dresden}},
     year={2016},
     url={https://github.com/VLSI-EDA/PoC},
     urldate={2016-10-28},
   }

.. toctree::
   :caption: Introduction
   :hidden:

   WhatIsPoC/index
   QuickStart
   UsingPoC/index
   GetInvolved/index
   References/Licenses/License

.. toctree::
   :caption: Main Documentation
   :hidden:

   Interfaces/index
   IPCores/index
   Miscelaneous/ThirdParty
   ConstraintFiles/index

.. toctree::
   :caption: References
   :hidden:

   References/CommandReference
   References/Database
   PyInfrastructure/index
   More ... <References/more>

.. toctree::
   :caption: Appendix
   :hidden:

   Miscelaneous/ChangeLog
   genindex
