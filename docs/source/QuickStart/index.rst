.. |br| raw:: html

   <br />

Quick Start Guide
#################

.. contents:: Contents of this Page:

Download
********

The PoC-Library can be downloaded as a `zip-file <https://github.com/VLSI-EDA/PoC/archive/master.zip>`_ (latest 'master' branch) or cloned with
``git clone`` from GitHub. GitHub offers HTTPS and SSH as transfer protocols. See the :doc:`Download` page for further details.

+----------+---------------------------------------------------------------------+
| Protocol | Git clone command                                                   |
+==========+=====================================================================+
| HTTPS    | ``git clone --recursive https://github.com/VLSI-EDA/PoC.git PoC``   |
+----------+---------------------------------------------------------------------+
| SSH      | ``git clone --recursive ssh://git@github.com:VLSI-EDA/PoC.git PoC`` |
+----------+---------------------------------------------------------------------+

.. toctree::
   :hidden:
   
   Download


Requirements
************

The PoC-Library comes with some scripts to ease most of the common tasks, like
running testbenches or generating IP cores. We choose to use Python 3 as a
platform independent scripting environment. All Python scripts are wrapped in
Bash or PowerShell scripts, to hide some platform specifics of Darwin, Linux or
Windows. See the :doc:`Requirements` page for further details.

**PoC requires:**

* The Python3 programming language and runtime
* Git, if you want to checkout the latest release branch
* A :doc:`supported synthesis tool chain </Introduction/index>`, if you want to synthezise IP cores.
* A :doc:`supported simulator too chain </Introduction/index>`, if you want to simulate IP cores.

.. toctree::
   :hidden:
   
   Requirements


Dependencies
************

**The PoC-Library depends on:**

* `Cocotb <https://github.com/potentialventures/cocotb>`_ |br|
  A coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python.
* `OS-VVM <https://github.com/JimLewis/OSVVM>`_ |br|
  Open Source VHDL Verification Methodology.
* `VUnit <https://github.com/VUnit/vunit>`_ |br|
  An unit testing framework for VHDL.

All dependencies are available as GitHub repositories and are linked to
PoC as git submodules into the `<PoCRoot>\lib\ <https://github.com/VLSI-EDA/PoC/tree/master/lib>`_ directory.


Configuring PoC on a Local System (Stand Alone)
***********************************************

To explore PoC's full potential, it's required to configure some paths and synthesis or simulation tool chains. The following commands start a guided
configuration process. Please follow the instructions. It's possible to relaunch the process at every time, for example to register new tools or to update
tool versions. See the `Configuration] for more details.

Run the following command line instructions to configure PoC on your local system.

.. code-block:: posh
   
   cd <PoCRoot>
   .\poc.ps1 configure

Press :kbd:`P` to skip a step.
		
**Note:** The configuration process can be re-run at every time to add, remove or update choices made.

If you want to check your installation, you can run one of our testbenches as described in `tb/README.md]

.. toctree::
   :hidden:
   
   Configuration

Integration
***********

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor
sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet

.. toctree::
   :hidden:
   
   Integration

Using PoC
*********

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor
sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet

.. toctree::
   :hidden:
   
   Using

Updating
********

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor
sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet

.. toctree::
   :hidden:
   
   Updating
