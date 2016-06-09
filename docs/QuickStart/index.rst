
Quick Start Guide
#################

.. contents:: Contents of this Page
   :local:


Requirements and Dependencies
*****************************

The PoC-Library comes with some scripts to ease most of the common tasks, like
running testbenches or generating IP cores. PoC uses Python 3 as a platform
independent scripting environment. All Python scripts are wrapped in Bash or
PowerShell scripts, to hide some platform specifics of Darwin, Linux or Windows.
See the :doc:`RequirementDetails` page for further details.


.. rubric:: PoC requires:

* A :doc:`supported synthesis tool chain </WhatIsPoC/SupportedToolChains>`, if you want to synthezise IP cores.
* A :doc:`supported simulator too chain </WhatIsPoC/SupportedToolChains>`, if you want to simulate IP cores.
* The Python3 programming language and runtime.


.. rubric:: PoC optionally requires:

* Git, if you want to checkout the latest 'master' or 'release' branch.


.. rubric:: Third Parts Library Dependencies

* `Cocotb <https://github.com/potentialventures/cocotb>`_ |br|
  A coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python.
* `OS-VVM <https://github.com/JimLewis/OSVVM>`_ |br|
  Open Source VHDL Verification Methodology.
* `VUnit <https://github.com/VUnit/vunit>`_ |br|
  An unit testing framework for VHDL.

All dependencies are available as GitHub repositories and are linked to
PoC as Git submodules into the `<PoCRoot>\\lib <https://github.com/VLSI-EDA/PoC/tree/master/lib>`_
directory. See the :doc:`Third-Party </Miscelaneous/ThirdParty>` page for more details on these libraries.

.. toctree::
   :hidden:
   
   RequirementDetails


Download
********

The PoC-Library can be downloaded as a `zip-file <https://github.com/VLSI-EDA/PoC/archive/master.zip>`_
(latest 'master' branch), cloned with ``git clone`` or embedded with
``git submodule add`` from GitHub. GitHub offers HTTPS and SSH as transfer
protocols. See the :doc:`DownloadDetails` page for further details.

+----------+---------------------------------------------------------------------+
| Protocol | Git Clone Command                                                   |
+==========+=====================================================================+
| HTTPS    | ``git clone --recursive https://github.com/VLSI-EDA/PoC.git PoC``   |
+----------+---------------------------------------------------------------------+
| SSH      | ``git clone --recursive ssh://git@github.com:VLSI-EDA/PoC.git PoC`` |
+----------+---------------------------------------------------------------------+

.. toctree::
   :hidden:
   
   DownloadDetails


Configuring PoC on a Local System
*********************************

To explore PoC's full potential, it's required to configure some paths and
synthesis or simulation tool chains. The following commands start a guided
configuration process. Please follow the instructions. It's possible to relaunch
the process at any time, for example to register new tools or to update tool
versions. See the :doc:`Configuration Details <ConfigurationDetails>` page for
more details.

Run the following command line instructions to configure PoC on your local system.

.. code-block:: PowerShell
   
   cd <PoCRoot>
   .\poc.ps1 configure

Use the keyboard buttons: :kbd:`Y` to accept, :kbd:`N` to decline, :kbd:`P` to
skip/pass a step and :kbd:`Return` to accept a default value displayed in brackets.

.. 
   Note::
   The configuration process can be re-run at any time to add, remove or update
   choices made.

.. seealso::
   :doc:`Running one or more testbenches </UsingPoC/Simulation>`
      The installation can be checked by running one or more of PoC's testbenches.
   :doc:`Running one or more netlist generation flows </UsingPoC/Synthesis>`
      The installation can also be checked by running one or more of PoC's
      synthesis flows.

.. toctree::
   :hidden:
   
   ConfigurationDetails

Integration
***********

The PoC-Library is meant to be integrated into other HDL projects. Therefore
it's recommended to create a library folder and add the PoC-Library as a Git
submodule. After the repository linking is done, some short configuration
steps are required to setup paths, tool chains and the target platform. The
following command line instructions show a short example on how to integrate
PoC. A detailed list of steps can be found on the :doc:`Integration Details </QuickStart/IntegrationDetails>`
page.

.. rubric:: 1. Adding the Library as a Git submodule

The following command line instructions will create the folder ``lib\PoC\`` and
clone the PoC-Library as a Git `submodule <http://git-scm.com/book/en/v2/Git-Tools-Submodules>`_
into that folder. ``ProjectRoot`` is the directory of the hosting Git.

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

The PoC-Library should be configured to explore it's full potential:

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

`common/my_config.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/common/my_config.vhdl.template>`_ defines two global constants, which need to be adjusted:

.. code-block:: vhdl
   
   constant MY_BOARD            : string := "CHANGE THIS"; -- e.g. Custom, ML505, KC705, Atlys
   constant MY_DEVICE           : string := "CHANGE THIS"; -- e.g. None, XC5VLX50T-1FF1136, EP2SGX90FF1508C3

`my_project.vhdl <https://github.com/VLSI-EDA/PoC/blob/master/src/common/my_project.vhdl.template>`_
also defines two global constants, which need to be adjusted:

.. code-block:: vhdl
   
   constant MY_PROJECT_DIR      : string := "CHANGE THIS"; -- e.g. d:/vhdl/myproject/, /home/me/projects/myproject/"
   constant MY_OPERATING_SYSTEM : string := "CHANGE THIS"; -- e.g. WINDOWS, LINUX


.. rubric:: 4. Adding PoC's Common Packages to a Synthesis or Simulation Project

PoC is shipped with a set of common packages, which are used by most of it's
modules. These packages are stored in the ``PoCRoot\src\common`` directory.
PoC also provides a VHDL ``context``, which can be used to reference all packages
at once.


.. rubric:: 5. Adding PoC's Simulation Packages to a Simulation Project

Simulation projects additionally require PoC's simulation helper packages, which
are located in the ``PoCRoot\src\sim`` directory. Because some VHDL version are
incompatible among each other, PoC uses version suffixes like ``*.v93.vhdl`` or
``*.v08.vhdl`` in the file name to denote the supported VHDL version of a file.


.. rubric:: 6. Compiling Shipped IP Cores

Some IP Cores are shipped are pre-configured vendor IP Cores. If such IP cores
shall be used in a HDL project, it's recommended to use PoC to create, compile
and if needed patch these IP cores. See the :doc:`Synthesis </UsingPoC/Synthesis>`
page for more details.


.. toctree::
   :hidden:
   
   IntegrationDetails


Updating
********

The PoC-Library can be updated by using ``git fetch`` and ``git merge``.

.. code-block:: PowerShell

    cd PoCRoot
    # update the local repository
    git fetch --prune
    # review the commit tree and messages, using the 'treea' alias
    git treea
    # if all changes are OK, do a fast-forward merge
    git merge


.. toctree::
   :hidden:
   
   UpdatingDetails
	 