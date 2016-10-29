
What is the History of PoC?
###########################

In the past years, a lot of "IP cores" were developed at the chair of VLSI
design [#f1]_ . This lose set of HDL designs was gathered in an old-fashioned
CVS repository and grow over the years to a collection of basic HDL
implementations like ALUs, FIFOs, UARTs or RAM controllers. For their final
projects (bachelor, master, diploma thesis) students got access to PoC, so they
could focus more on their main tasks than wasting time in developing and
testing basic IP implementations from scratch. But the library was initially
for internal and educational use only.

As a university chair for VLSI design, we have a wide range of different FPGA
prototyping boards from various vendors and device families as well as
generations. So most of the IP cores were developed for both major FPGA vendor
platforms and their specific vendor tool chains. The main focus was to describe
hardware in a more flexible and generic way, so that an IP core could be reused
on multiple target platforms.

As the number of cores increased, the set of common functions and types
increased too. In the end PoC is not only a collection of IP cores, its also
shipped with a set of packages containing utility functions, new types and type
conversions, which are used by most of the cores. This makes PoC a *library*,
not only a *collection* of IPs.

As we started to search for ways to publish IP cores and maybe the whole
PoC-Library, we found several platforms on the Internet, but none was very
convincing. Some collective websites contained inactive projects, others were
controlled by companies without the possibility to contribute and the majority
was a long list of private projects with at most a handful of IP cores. Another
disagreement were the used license types for these projects. We decided to use
the Apache License, because it has no copyleft rule, a patent clause and allows
commercial usage.

We transformed the old CVS repository into three Git repositories: An internal
repository for the full set of IP cores (incl. classified code), a public one
and a repository for examples, called PoC-Examples, both hosted on GitHub. PoC
itself can be integrated into other HDL projects as a library directory or a Git
submodule. The preferred usage is the submodule integration, which has the
advantage of linked repository versions from hosting Git and the submodule Git.
This is already exemplified by our PoC-Examples repository.

----------------------------------------------------

.. rubric:: Footnotes

.. [#f1] The PoC-Library is published and maintained by the **Chair for VLSI
   Design, Diagnostics and Architecture** - Faculty of Computer Science,
   Technische Universität Dresden, Germany |br|
   `http://tu-dresden.de/inf/vlsi-eda <http://tu-dresden.de/inf/vlsi-eda>`_
