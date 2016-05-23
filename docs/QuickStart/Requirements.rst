
Requirement Details
###################

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
  
  * `Python 3 <https://www.python.org/downloads/>`_ (≥3.5):
    
    * `colorama <https://pypi.python.org/pypi/colorama>`_
    * `py-flags <https://pypi.python.org/pypi/py-flags>`_
    
    All Python requirements are listed in `requirements.txt <https://github.com/VLSI-EDA/PoC/blob/master/requirements.txt>`_ and can be installed via: |br|
    ``sudo python3.5 -m pip install -r requirements.txt``
  
* Synthesis tool chains:
  
  * Altera Quartus ≥13.0 or
  * Lattice Diamond or
  * Xilinx ISE 14.7 [#f1]_ or
  * Xilinx Vivado [#f2]_
  
* Simulation tool chains
  
  * Aldec Active-HDL or
  * Mentor Graphics ModelSim Altera Edition or
  * Mentor Graphics QuestaSim or
  * Xilinx ISE Simulator 14.7 [#f1]_ or
  * Xilinx Vivado Simulator ≥2016.1 [#f2]_ or
  * `GHDL <https://sourceforge.net/projects/ghdl-updates/>`_ ≥0.34dev and `GTKWave <http://gtkwave.sourceforge.net/>`_ ≥3.3.70


Linux specific requirements:
****************************
 
* Debian and Ubuntu specific:
  
  * bash is configured as :file:`/bin/sh` (`read more <https://wiki.debian.org/DashAsBinSh>`_) |br|
    ``dpkg-reconfigure dash``


Optional Tools on Linux:
========================

* `Generic Colouriser <http://kassiopeia.juls.savba.sk/~garabik/software/grc.html>`_ (grc) ≥1.9 |br|
  Git repository on GitHub -> `https://github.com/garabik/grc <https://github.com/garabik/grc>`_ |br|
  *.deb package for Debian -> `http://kassiopeia.juls.savba.sk/~garabik/software/grc/ <http://kassiopeia.juls.savba.sk/~garabik/software/grc/>`_


Windows specific requirements:
******************************

* PowerShell 4.0 (`Windows Management Framework 4.0 <http://www.microsoft.com/en-US/download/details.aspx?id=40855>`_)
  
  * Allow local script execution (`read more <https://technet.microsoft.com/en-us/library/hh849812.aspx>`_) |br|
    ``Set-ExecutionPolicy RemoteSigned``
  
  * PowerShell Community Extensions 3.2 (`pscx.codeplex.com <http://pscx.codeplex.com/>`_)

Optional Tools on Windows:
==========================

* `posh-git <https://github.com/dahlbyk/posh-git>`_ - PowerShell integration for Git |br|
  Installing posh-git with `PsGet <http://psget.net/>`_ package manager: ``Install-Module posh-git``

	
------------------------------------------

.. rubric:: Footnotes

.. [#f1] Xilinx discontinued ISE since Oct. 2013. The last release was 14.7. 
.. [#f2] Due to numerous bugs in the Xilinx Vivado Synthesis and Vivado
   Simulator (incl. 2016.1), PoC can offer only a restricted Vivado support.
