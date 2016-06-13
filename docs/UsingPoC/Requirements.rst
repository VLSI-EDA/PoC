.. # Load pre-defined aliases from docutils
   # <file> is used to denote the special path

.. include:: <mmlalias.txt>


Requirements
############

.. contents:: Contents of this Page
   :local:

The PoC-Library comes with some scripts to ease most of the common tasks, like
running testbenches or generating IP cores. We choose to use Python 3 as a
platform independent scripting environment. All Python scripts are wrapped in
Bash or PowerShell scripts, to hide some platform specifics of Darwin, Linux or
Windows.

Common requirements:
********************

* Programming Languages and Runtime Environments:
  
  * `Python 3 <https://www.python.org/downloads/>`_ (|geq| 3.5):
    
    * `colorama <https://pypi.python.org/pypi/colorama>`_
    * `py-flags <https://pypi.python.org/pypi/py-flags>`_
    
    All Python requirements are listed in `requirements.txt <https://github.com/VLSI-EDA/PoC/blob/master/requirements.txt>`_ and can be installed via: |br|
    ``sudo python3.5 -m pip install -r requirements.txt``
  
* Synthesis tool chains:
  
  * Altera Quartus |geq| 13.0 or
  * Lattice Diamond or
  * Xilinx ISE 14.7 [#f1]_ or
  * Xilinx Vivado [#f2]_
  
* Simulation tool chains
  
  * Aldec Active-HDL or
  * Mentor Graphics ModelSim Altera Edition or
  * Mentor Graphics QuestaSim or
  * Xilinx ISE Simulator 14.7 or
  * Xilinx Vivado Simulator |geq| 2016.1 [#f3]_ or
  * `GHDL <https://github.com/tgingold/ghdl>`_ |geq| 0.34dev and `GTKWave <http://gtkwave.sourceforge.net/>`_ |geq| 3.3.70


Linux specific requirements:
****************************

* Debian and Ubuntu specific:
  
  * bash is configured as :file:`/bin/sh` (`read more <https://wiki.debian.org/DashAsBinSh>`_) |br|
    ``dpkg-reconfigure dash``


Optional Tools on Linux:
========================

* Git
    The command line tools to manage Git repositories. It's possible to extend
    the shell prompt with Git information.

* SmartGit
    A Git client to handle complex Git flows in a GUI.

* `Generic Colouriser <http://kassiopeia.juls.savba.sk/~garabik/software/grc.html>`_ (grc) |geq| 1.9
    Colorizes outputs of foreign scripts and programs. GRC is hosted on `GitHub <https://github.com/garabik/grc>`_
    The latest *.deb installation packages can be downloaded `here <http://kassiopeia.juls.savba.sk/~garabik/software/grc/>`_.


Windows specific requirements:
******************************

* PowerShell |geq| 4.0
    PowerShell shipped with Windows since Vista. It is a part if the Windows
    Management Framework. If the required version not already included in
    Windows, it can be downloaded from microsoft.com: `WMF 4.0 <http://www.microsoft.com/en-US/download/details.aspx?id=40855>`_,
    `WMF 5.0 <https://www.microsoft.com/en-US/download/details.aspx?id=50395>`_ (recommended).
  
  * Allow local script execution (`read more <https://technet.microsoft.com/en-us/library/hh849812.aspx>`_) |br|
    ``Set-ExecutionPolicy RemoteSigned``
  * PowerShell Community Extensions (PSCX) |geq| 3.2 |br|
    The latest PSCX can be downloaded from `PowerShellGallery <https://www.powershellgallery.com/packages/Pscx/>`_


Optional Tools on Windows:
==========================

* Git (MSys-Git)
    The command line tools to manage Git repositories.

* SmartGit or SourceTree
    A Git client to handle complex Git flows in a GUI.

* `posh-git <https://github.com/dahlbyk/posh-git>`_
    PowerShell integration for Git |br|
    Installing posh-git with `PsGet <http://psget.net/>`_ package manager: ``Install-Module posh-git``


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
