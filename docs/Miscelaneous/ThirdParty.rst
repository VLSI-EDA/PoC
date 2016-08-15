Third Party Libraries
#####################

The PoC-Library is shiped with different third party libraries, which are
located in the ``<PoCRoot>/lib/`` folder. This document lists all these
libraries, their websites and licenses.


Cocotb
******

`Cocotb <http://cocotb.readthedocs.org/>`_ is a coroutine based cosimulation
library for writing VHDL and Verilog testbenches in Python.

+--------------------+-----------------------------------------------------------------------------------------------------------+
| **Folder:**        | ``<PoCRoot>\lib\cocotb\``                                                                                 |
+--------------------+-----------------------------------------------------------------------------------------------------------+
| **Copyright:**     | Copyright © 2013, `Potential Ventures Ltd. <http://potential.ventures/>`_, SolarFlare Communications Inc. |
+--------------------+-----------------------------------------------------------------------------------------------------------+
| **License:**       | :doc:`Revised BSD License (local copy) </References/Licenses/BSDLicense_Cocotb>`                          |
+--------------------+-----------------------------------------------------------------------------------------------------------+
| **Documentation:** | `http://cocotb.readthedocs.org/ <http://cocotb.readthedocs.org/>`_                                        |
+--------------------+-----------------------------------------------------------------------------------------------------------+
| **Source:**        | `https://github.com/potentialventures/cocotb <https://github.com/potentialventures/cocotb>`_              |
+--------------------+-----------------------------------------------------------------------------------------------------------+


OSVVM
*****

**Open Source VHDL Verification Methodology (OS-VVM)** is an intelligent
testbench methodology that allows mixing of “Intelligent Coverage” (coverage
driven randomization) with directed, algorithmic, file based, and constrained
random test approaches. The methodology can be adopted in part or in whole as
needed. With OSVVM you can add advanced verification methodologies to your
current testbench without having to learn a new language or throw out your
existing testbench or testbench models.

+----------------+---------------------------------------------------------------------------------------+
| **Folder:**    | ``<PoCRoot>\lib\osvvm\``                                                              |
+----------------+---------------------------------------------------------------------------------------+
| **Copyright:** | Copyright © 2012-2016 by `SynthWorks Design Inc. <http://www.synthworks.com/>`_       |
+----------------+---------------------------------------------------------------------------------------+
| **License:**   | :doc:`Artistic License 2.0 (local copy) </References/Licenses/ArtisticLicense2.0>`    |
+----------------+---------------------------------------------------------------------------------------+
| **Website:**   | `http://osvvm.org/ <http://osvvm.org/>`_                                              |
+----------------+---------------------------------------------------------------------------------------+
| **Source:**    | `https://github.com/JimLewis/OSVVM <https://github.com/JimLewis/OSVVM>`_              |
+----------------+---------------------------------------------------------------------------------------+


VUnit
*****

`VUnit <https://vunit.github.io/>`_ is an open source unit testing framework for
VHDL released under the terms of :doc:`Mozilla Public License, v. 2.0 </References/Licenses/MozillaPublicLicense2.0>`.
It features the functionality needed to realize continuous and automated testing
of your VHDL code. VUnit doesn't replace but rather complements traditional
testing methodologies by supporting a "test early and often" approach through
automation.

+----------------+---------------------------------------------------------------------------------------------------------------+
| **Folder:**    | ``<PoCRoot>\lib\vunit\``                                                                                      |
+----------------+---------------------------------------------------------------------------------------------------------------+
| **Copyright:** | Copyright © 2014-2016, Lars Asplund `lars.anders.asplund@gmail.com <mailto://lars.anders.asplund@gmail.com>`_ |
+----------------+---------------------------------------------------------------------------------------------------------------+
| **License:**   | :doc:`Mozilla Public License, Version 2.0 (local copy) </References/Licenses/MozillaPublicLicense2.0>`        |
+----------------+---------------------------------------------------------------------------------------------------------------+
| **Website:**   | `https://vunit.github.io/ <https://vunit.github.io/>`_                                                        |
+----------------+---------------------------------------------------------------------------------------------------------------+
| **Source:**    | `https://github.com/VUnit/vunit <https://github.com/VUnit/vunit>`_                                            |
+----------------+---------------------------------------------------------------------------------------------------------------+


Updating Linked Git Submodules
******************************

The third party libraries are embedded as Git submodules. So if the PoC-Library
was not cloned with option ``--recursive`` it's required to run the sub-module
initialization manually:

On Linux
========

.. code-block:: Bash
   
   cd PoCRoot
   git submodule init
   git submodule update

We recommend to rename the default remote repository name from 'origin' to
'github'.

.. code-block:: Bash
   
   cd PoCRoot\lib\

.. todo:: write Bash code for Linux

On OS X
=======

Please see the Linux instructions.

On Windows
==========


.. code-block:: PowerShell
   
   cd PoCRoot
   git submodule init
   git submodule update

We recommend to rename the default remote repository name from 'origin' to
'github'.

.. code-block:: PowerShell
   
   cd PoCRoot\lib\
   foreach($dir in (dir -Directory)) {
     cd $dir
     git remote rename origin github
     cd ..
   }

