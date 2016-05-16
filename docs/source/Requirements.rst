Requirements
********************************************************************************

**The PoC-Library** comes with some scripts to ease most of the common tasks, like running testbenches or generating IP cores. We choose to use Python as a
platform independent scripting environment. All Python scripts are wrapped in PowerShell or Bash scripts, to hide some platform specifics of Windows or Linux.
See the `Requirements] for more details and download sources.

Common requirements:
====================

* Programming Languages and Runtime Environments:

  * `Python 3 <https://www.python.org/downloads/>`_ (&ge; 3.5):
  
    * `colorama <https://pypi.python.org/pypi/colorama>`_
    * `py-flags <https://pypi.python.org/pypi/py-flags>`_
    
    All Python requirements are listed in `requirements.txt <https://github.com/VLSI-EDA/PoC/tree/master/requirements.txt>`_ and can be installed via:
    ``sudo python3.5 -m pip install -r requirements.txt``
    
  * Synthesis tool chains:
  
    * Altera Quartus-II &ge; 13.0 or
    * Lattice Diamond or
    * Xilinx ISE 14.7 or
    * Xilinx Vivado (restricted, see `section 7.7])
    
  * Simulation tool chains:
  
    * Aldec Active-HDL or
    * Mentor Graphics ModelSim Altera Edition or
    * Mentor Graphics QuestaSim or
    * Xilinx ISE Simulator 14.7 or
    * Xilinx Vivado Simulator &ge; 2016.1 or
    * `GHDL <https://sourceforge.net/projects/ghdl-updates/>`_ &ge; 0.34dev and `GTKWave <http://gtkwave.sourceforge.net/>`_ &ge; 3.3.70


Linux specific requirements:
============================
 
* Debian and Ubuntu specific:

  * bash is configured as ``/bin/sh`` (`read more](https://wiki.debian.org/DashAsBinSh))
    ``dpkg-reconfigure dash``
 
Windows specific requirements:
==============================

* PowerShell 4.0 (`Windows Management Framework 4.0 <http://www.microsoft.com/en-US/download/details.aspx?id=40855>`_)
 
  * Allow local script execution (`read more <https://technet.microsoft.com/en-us/library/hh849812.aspx>`_)  
    ``Set-ExecutionPolicy RemoteSigned``
  * PowerShell Community Extensions 3.2 (`pscx.codeplex.com <http://pscx.codeplex.com/>`_)
