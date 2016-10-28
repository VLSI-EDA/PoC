.. |br| raw:: html

   <br />

The PoC-Library
***************

.. image:: docs/_static/logos/GitHub-Mark-32px.png
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

This library is published and maintained by **Chair for VLSI Design, Diagnostics
and Architecture** - Faculty of Computer Science, Technische Universität Dresden,
Germany |br|
`http://tu-dresden.de/inf/vlsi-eda <http://tu-dresden.de/inf/vlsi-eda>`_

.. image:: docs/_static/images/logo_tud.jpg
   :scale: 10
   :alt: Logo: Technische Universität Dresden

.. contents:: Contents of this Page
   :local:


Overview
********

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



Quick Start Guide
*****************

This **quick start guide** gives a fast and simple introduction into PoC. All
topics can be found in the `Using PoC <http://poc-library.readthedocs.io/en/latest/UsingPoC/index.html>`_ section with much
more details and examples.


Requirements and Dependencies
=============================

The PoC-Library comes with some scripts to ease most of the common tasks, like
running testbenches or generating IP cores. PoC uses **Python 3** as a platform
independent scripting environment. All Python scripts are wrapped in Bash or
PowerShell scripts, to hide some platform specifics of Darwin, Linux or Windows.
See `Requirements <http://poc-library.readthedocs.io/en/latest/UsingPoC/Requirements.html>`_ for further details.


.. rubric:: PoC requires:

* A `supported synthesis tool chain <http://poc-library.readthedocs.io/en/latest/WhatIsPoC/SupportedToolChains.html>`_, if you want to synthezise IP cores.
* A `supported simulator too chain <http://poc-library.readthedocs.io/en/latest/WhatIsPoC/SupportedToolChains.html>`_, if you want to simulate IP cores.
* The Python3 programming language and runtime, if you want to use PoC's infrastructure.
* A shell to execute shell scripts:

  * Bash on Linux and OS X
  * PowerShell on Windows


.. rubric:: PoC optionally requires:

* Git command line tools or a Git GUI, if you want to check out the latest 'master' or 'release' branch.


.. rubric:: PoC depends on third parts libraries:

* `Cocotb <https://github.com/potentialventures/cocotb>`_ |br|
  A coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python.
* `OS-VVM <https://github.com/JimLewis/OSVVM>`_ |br|
  Open Source VHDL Verification Methodology.
* `VUnit <https://github.com/VUnit/vunit>`_ |br|
  An unit testing framework for VHDL.

All dependencies are available as GitHub repositories and are linked to
PoC as Git submodules into the `PoCRoot\\lib <https://github.com/VLSI-EDA/PoC/tree/master/lib>`_
directory. See `Third Party Libraries <http://poc-library.readthedocs.io/en/latest/Miscelaneous/ThirdParty.html>`_ for more details on these libraries.


Download
========

The PoC-Library can be downloaded as a `zip-file <https://github.com/VLSI-EDA/PoC/archive/master.zip>`_
(latest 'master' branch), cloned with ``git clone`` or embedded with
``git submodule add`` from GitHub. GitHub offers HTTPS and SSH as transfer
protocols. See the `Download <http://poc-library.readthedocs.io/en/latest/UsingPoC/Download.html>`_ page for further
details. The installation directory is referred to as ``PoCRoot``.

+----------+---------------------------------------------------------------------+
| Protocol | Git Clone Command                                                   |
+==========+=====================================================================+
| HTTPS    | ``git clone --recursive https://github.com/VLSI-EDA/PoC.git PoC``   |
+----------+---------------------------------------------------------------------+
| SSH      | ``git clone --recursive ssh://git@github.com:VLSI-EDA/PoC.git PoC`` |
+----------+---------------------------------------------------------------------+


Configuring PoC on a Local System
=================================

To explore PoC's full potential, it's required to configure some paths and
synthesis or simulation tool chains. The following commands start a guided
configuration process. Please follow the instructions on screen. It's possible
to relaunch the process at any time, for example to register new tools or to
update tool versions. See `Configuration <http://poc-library.readthedocs.io/en/latest/UsingPoC/PoCConfiguration.html>`_ for
more details. Run the following command line instructions to configure PoC on
your local system:

.. code-block:: PowerShell

   cd PoCRoot
   .\poc.ps1 configure

Use the keyboard buttons: :kbd:`Y` to accept, :kbd:`N` to decline, :kbd:`P` to
skip/pass a step and :kbd:`Return` to accept a default value displayed in brackets.


Integration
===========

The PoC-Library is meant to be integrated into other HDL projects. Therefore
it's recommended to create a library folder and add the PoC-Library as a Git
submodule. After the repository linking is done, some short configuration
steps are required to setup paths, tool chains and the target platform. The
following command line instructions show a short example on how to integrate
PoC.

.. rubric:: 1. Adding the Library as a Git submodule

The following command line instructions will create the folder ``lib\PoC\`` and
clone the PoC-Library as a Git `submodule <http://git-scm.com/book/en/v2/Git-Tools-Submodules>`_
into that folder. ``ProjectRoot`` is the directory of the hosting Git. A detailed
list of steps can be found at `Integration <http://poc-library.readthedocs.io/en/latest/UsingPoC/Integration.html>`_.

.. code-block:: powershell

   cd ProjectRoot
   mkdir lib | cd
   git submodule add https://github.com:VLSI-EDA/PoC.git PoC
   cd PoC
   git remote rename origin github
   cd ..\..
   git add .gitmodules lib\PoC
   git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."

.. rubric:: 2. Configuring PoC

The PoC-Library should be configured to explore it's full potential. See
`Configuration <http://poc-library.readthedocs.io/en/latest/UsingPoC/PoCConfiguration.html>`_ for more details. The
following command lines will start the configuration process:

.. code-block:: powershell

   cd ProjectRoot
   .\lib\PoC\poc.ps1 configure


.. rubric:: 3. Creating PoC's ``my_config.vhdl`` and ``my_project.vhdl`` Files

The PoC-Library needs two VHDL files for it's configuration. These files are
used to determine the most suitable implementation depending on the provided
target information. Copy the following two template files into your project's
source folder. Rename these files to \*.vhdl and configure the VHDL constants
in the files:

.. code-block:: powershell

   cd ProjectRoot
   cp lib\PoC\src\common\my_config.vhdl.template src\common\my_config.vhdl
   cp lib\PoC\src\common\my_project.vhdl.template src\common\my_project.vhdl

`my_config.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/common/my_config.vhdl.template>`_ defines two global constants, which need to be adjusted:

.. code-block:: vhdl

   constant MY_BOARD            : string := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
   constant MY_DEVICE           : string := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3

`my_project.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/common/my_project.vhdl.template>`_
also defines two global constants, which need to be adjusted:

.. code-block:: vhdl

   constant MY_PROJECT_DIR      : string := "CHANGE THIS"; -- e.g. d:/vhdl/myproject/, /home/me/projects/myproject/"
   constant MY_OPERATING_SYSTEM : string := "CHANGE THIS"; -- e.g. WINDOWS, LINUX

Further informations are provided at
`Creating my_config/my_project.vhdl <http://poc-library.readthedocs.io/en/latest/UsingPoC/VHDLConfiguration.html>`_.

.. rubric:: 4. Adding PoC's Common Packages to a Synthesis or Simulation Project

PoC is shipped with a set of common packages, which are used by most of it's
modules. These packages are stored in the ``PoCRoot\src\common`` directory.
PoC also provides a VHDL context in ``common.vhdl`` , which can be used to
reference all packages at once.


.. rubric:: 5. Adding PoC's Simulation Packages to a Simulation Project

Simulation projects additionally require PoC's simulation helper packages, which
are located in the ``PoCRoot\src\sim`` directory. Because some VHDL version are
incompatible among each other, PoC uses version suffixes like ``*.v93.vhdl`` or
``*.v08.vhdl`` in the file name to denote the supported VHDL version of a file.


.. rubric:: 6. Compiling Shipped IP Cores

Some IP Cores are shipped are pre-configured vendor IP Cores. If such IP cores
shall be used in a HDL project, it's recommended to use PoC to create, compile
and if needed patch these IP cores. See `Synthesis <http://poc-library.readthedocs.io/en/latest/UsingPoC/Synthesis.html>`_
for more details.


Updating
========

The PoC-Library can be updated by using ``git fetch`` and ``git merge``.

.. code-block:: PowerShell

   cd PoCRoot
   * update the local repository
   git fetch --prune
   * review the commit tree and messages, using the 'treea' alias
   git treea
   * if all changes are OK, do a fast-forward merge
   git merge


.. seealso::
   `Running one or more testbenches <http://poc-library.readthedocs.io/en/latest/UsingPoC/Simulation.html>`_
      The installation can be checked by running one or more of PoC's testbenches.
   `Running one or more netlist generation flows <http://poc-library.readthedocs.io/en/latest/UsingPoC/Synthesis.html>`_
      The installation can also be checked by running one or more of PoC's
      synthesis flows.


Cite the PoC-Library
====================

The PoC-Library hosted at `GitHub.com <https://www.github.com>`_. Please use the
following `bitlatex <https://www.ctan.org/pkg/biblatex>`_ entry to cite us:

.. code-block:: tex

   * BibLaTex example entry
   @online{poc,
     title={{PoC - Pile of Cores}},
     author={{Chair of VLSI Design, Diagnostics and Architecture}},
     organization={{Technische Universität Dresden}},
     year={2016},
     url={https://github.com/VLSI-EDA/PoC},
     urldate={2016-10-28},
   }
