.. _USING:Require:

Requirements
############

.. contents:: Contents of this Page
   :local:

The PoC-Library comes with some scripts to ease most of the common tasks, like
running testbenches or generating IP cores. We choose to use Python 3 as a
platform independent scripting environment. All Python scripts are wrapped in
Bash or PowerShell scripts, to hide some platform specifics of Darwin, Linux or
Windows.

.. _USING:Require:Common:

Common requirements:
********************

Programming Languages and Runtime Environments:
  * `Python 3 <https://www.python.org/downloads/>`_ (|geq| 3.5):

    * `colorama <https://pypi.python.org/pypi/colorama>`_
    * `py-flags <https://pypi.python.org/pypi/py-flags>`_

    All Python requirements are listed in `requirements.txt <https://github.com/VLSI-EDA/PoC/blob/master/requirements.txt>`_ and can be installed via: |br|
    ``sudo python3.5 -m pip install -r requirements.txt``
Synthesis tool chains:
  * Altera Quartus II |geq| 13.0 or
  * Altera Quartus Prime |geq| 15.1 or
  * Intel Quartus Prime |geq| 16.1 or
  * Lattice Diamond |geq| 3.6 or
  * Xilinx ISE 14.7 [#f1]_ or
  * Xilinx Vivado |geq| 2016.3 [#f2]_
Simulation tool chains
  * Aldec Active-HDL (or Student Edition) or
  * Aldec Active-HDL Lattice Edition or
  * Mentor Graphics ModelSim PE (or Student Edition) or
  * Mentor Graphics ModelSim SE or
  * Mentor Graphics ModelSim Altera Edition or
  * Mentor Graphics QuestaSim or
  * Xilinx ISE Simulator 14.7 or
  * Xilinx Vivado Simulator |geq| 2016.3 [#f3]_ or
  * `GHDL <https://github.com/tgingold/ghdl>`_ |geq| 0.34dev and `GTKWave <http://gtkwave.sourceforge.net/>`_ |geq| 3.3.70


.. _USING:Require:Linux:

Linux specific requirements:
****************************

Debian and Ubuntu specific:
  * ``bash`` is configured as :file:`/bin/sh` (`read more <https://wiki.debian.org/DashAsBinSh>`_) |br|
    ``dpkg-reconfigure dash``


Optional Tools on Linux:
========================

Git
  The command line tools to manage Git repositories. It's possible to extend
  the shell prompt with Git information.
SmartGit
  A Git client to handle complex Git flows in a GUI.
`Generic Colouriser <http://kassiopeia.juls.savba.sk/~garabik/software/grc.html>`_ (grc) |geq| 1.9
  Colorizes outputs of foreign scripts and programs. GRC is hosted on `GitHub <https://github.com/garabik/grc>`_
  The latest *.deb installation packages can be downloaded `here <http://kassiopeia.juls.savba.sk/~garabik/software/grc/>`_.


.. _USING:Require:MacOS:

Mac OS specific requirements:
*****************************

Bash |geq| 4.3
  Mac OS is shipped with Bash 3.2. Use Homebrew to install an up-to-date Bash |br|
  ``brew install bash``
coreutils
  Mac OS' ``readlink`` program has a different behavior than the Linux version.
  The ``coreutils`` package installs a GNU readlink clone called ``greadlink``. |br|
  ``brew install coreutils``


Optional Tools on Mac OS:
=========================

Git
  The command line tools to manage Git repositories. It's possible to extend
  the shell prompt with Git information.
SmartGit or SourceTree
  A Git client to handle complex Git flows in a GUI.
`Generic Colouriser <http://kassiopeia.juls.savba.sk/~garabik/software/grc.html>`_ (grc) |geq| 1.9
  Colorizes outputs of foreign scripts and programs. GRC is hosted on `GitHub <https://github.com/garabik/grc>`_ |br|
  ``brew install Grc``


.. _USING:Require:Windows:

Windows specific requirements:
******************************

PowerShell
  * **Allow local script execution** (`read more <https://technet.microsoft.com/en-us/library/hh849812.aspx>`_) |br|
    ``PS> Set-ExecutionPolicy RemoteSigned``

  * **PowerShell** |geq| **5.0 (recommended)** |br|
    PowerShell 5.0 is shipped since Windows 10. It is a part if the `Windows Management Framework 5.0 <https://www.microsoft.com/en-US/download/details.aspx?id=50395>`_
    (WMF). Windows 7 and 8/8.1 can be updated to WMF 5.0. The package does not
    include **PSReadLine**, which is included in the Windows 10
    PowerShell environment. Install PSReadLine manually: |br|
    ``PS> Install-Module PSReadline``.

  * **PowerShell 4.0** |br|
    PowerShell is shipped with Windows since Vista. If the required version
    not already included in Windows, it can be downloaded from Microsoft.com:
    `WMF 4.0 <http://www.microsoft.com/en-US/download/details.aspx?id=40855>`_


Optional Tools on Windows:
==========================

PowerShell |geq| 4.0
  * **PSReadLine** replaces the command line editing experience in PowerShell for versions 3 and up.
  * **PowerShell Community Extensions (PSCX)** |geq| **3.2** |br|
    The latest PSCX can be downloaded from `PowerShellGallery <https://www.powershellgallery.com/packages/Pscx/>`_ |br|
    ``PS> Install-Module Pscx`` |br|
    Note: PSCX |geq| 3.2.1 is required for PowerShell |geq| 5.0.

Git (MSys-Git)
  The command line tools to manage Git repositories.

SmartGit or SourceTree
  A Git client to handle complex Git flows in a GUI.

`posh-git <https://github.com/dahlbyk/posh-git>`_
  PowerShell integration for Git |br|
  ``PS> Install-Module posh-git``

.. #   Installing posh-git with `PsGet <http://psget.net/>`_ package manager: |br|

------------------------------------------

.. rubric:: Footnotes

.. [#f1] Xilinx discontinued ISE since Oct. 2013. The last release was 14.7.
.. [#f2] Due to numerous bugs in the Xilinx Vivado Synthesis (incl. 2016.1), PoC
   can offer only a restricted Vivado support. See PoC's ``Vivado`` branch for a
   set of workarounds. The list of issues is documented on the
   :doc:`Known Issues </References/KnownIssues>` page.
.. [#f3] Due to numerous bugs in the Xilinx Simulator (incl. 2016.1), PoC can
   offer only a restricted Vivado support. The list of issues is documented on
   the :doc:`Known Issues </References/KnownIssues>` page.
