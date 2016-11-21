.. _USING:Download:

Downloading PoC
###############

.. contents:: Contents of this Page
   :local:


.. _USING:Zip:

Downloading from GitHub
***********************

The PoC-Library can be downloaded as a zip-file from GitHub. See the following
table, to choose your desired git branch.

.. |zip-master| image:: /_static/icons/ZIP.png
   :scale: 40
   :target: https://github.com/VLSI-EDA/PoC/archive/master.zip
   :alt: Source Code from GitHub - 'master' branch.
.. |zip-release| image:: /_static/icons/ZIP.png
   :scale: 40
   :target: https://github.com/VLSI-EDA/PoC/archive/release.zip
   :alt: Source Code from GitHub - 'release' branch.

+----------+------------------------+
| Branch   | Download Link          |
+==========+========================+
| master   | zip-file |zip-master|  |
+----------+------------------------+
| release  | zip-file |zip-release| |
+----------+------------------------+


.. _USING:GitClone:

Downloading via ``git clone``
*****************************

The PoC-Library can be downloaded (cloned) with ``git clone`` from GitHub.
GitHub offers the transfer protocols HTTPS and SSH. You should use SSH if you
have a GitHub account and have already uploaded an OpenSSH public key to GitHub,
otherwise use HTTPS if you have no account or you want to use login credentials.

The created folder :file:`<GitRoot>\\PoC` is used as :file:`<PoCRoot>` in later
instructions or on other pages in this documentation.

+----------+----------------------------------------+
| Protocol | GitHub Repository URL                  |
+==========+========================================+
| HTTPS    | https://github.com/VLSI-EDA/PoC.git    |
+----------+----------------------------------------+
| SSH      | ssh://git@github.com:VLSI-EDA/PoC.git  |
+----------+----------------------------------------+


On Linux
========

Command line instructions to clone the PoC-Library onto a Linux machine with
HTTPS protocol:

.. code-block:: Bash

   cd GitRoot
   git clone --recursive "https://github.com/VLSI-EDA/PoC.git" PoC
   cd PoC
   git remote rename origin github

Command line instructions to clone the PoC-Library onto a Linux machine machine
with SSH protocol:

.. code-block:: Bash

   cd GitRoot
   git clone --recursive "ssh://git@github.com:VLSI-EDA/PoC.git" PoC
   cd PoC
   git remote rename origin github


On OS X
========

Please see the Linux instructions.


On Windows
==========

.. NOTE::

   All Windows command line instructions are intended for :program:`Windows PowerShell`,
   if not marked otherwise. So executing the following instructions in Windows
   Command Prompt (:program:`cmd.exe`) won't function or result in errors! See
   the :ref:`Requirements section <USING:Require>` on where to
   download or update PowerShell.

Command line instructions to clone the PoC-Library onto a Windows machine with
HTTPS protocol:

.. code-block:: PowerShell

   cd GitRoot
   git clone --recursive "https://github.com/VLSI-EDA/PoC.git" PoC
   cd PoC
   git remote rename origin github

Command line instructions to clone the PoC-Library onto a Windows machine with
SSH protocol:

.. code-block:: PowerShell

   cd GitRoot
   git clone --recursive "ssh://git@github.com:VLSI-EDA/PoC.git" PoC
   cd PoC
   git remote rename origin github


.. NOTE::
   The option ``--recursive`` performs a recursive clone operation for all
   linked `git submodules <http://git-scm.com/book/en/v2/Git-Tools-Submodules>`_.
   An additional ``git submodule init`` and ``git submodule update`` call is not
   needed anymore.


.. _USING:GitSubmodule:

Downloading via ``git submodule add``
*************************************

The PoC-Library is meant to be integrated into other HDL projects (preferably
Git versioned projects). Therefore it's recommended to create a library folder
and add the PoC-Library as a `git submodule <http://git-scm.com/book/en/v2/Git-Tools-Submodules>`_.

The following command line instructions will create a library folder :file:`lib\`
and clone PoC as a git submodule into the subfolder :file:`<ProjectRoot>\lib\PoC\`.

On Linux
========

Command line instructions to clone the PoC-Library onto a Linux machine with
HTTPS protocol:

.. code-block:: Bash

   cd ProjectRoot
   mkdir lib
   git submodule add "https://github.com/VLSI-EDA/PoC.git" lib/PoC
   cd lib/PoC
   git remote rename origin github
   cd ../..
   git add .gitmodules lib/PoC
   git commit -m "Added new git submodule PoC in 'lib/PoC' (PoC-Library)."

Command line instructions to clone the PoC-Library onto a Linux machine machine
with SSH protocol:

.. code-block:: Bash

   cd ProjectRoot
   mkdir lib
   git submodule add "ssh://git@github.com:VLSI-EDA/PoC.git" lib/PoC
   cd lib/PoC
   git remote rename origin github
   cd ../..
   git add .gitmodules lib/PoC
   git commit -m "Added new git submodule PoC in 'lib/PoC' (PoC-Library)."


On OS X
========

Please see the Linux instructions.


On Windows
==========

.. NOTE::

   All Windows command line instructions are intended for :program:`Windows PowerShell`,
   if not marked otherwise. So executing the following instructions in Windows
   Command Prompt (:program:`cmd.exe`) won't function or result in errors! See
   the :ref:`Requirements section <USING:Require>` on where to
   download or update PowerShell.

Command line instructions to clone the PoC-Library onto a Windows machine with
HTTPS protocol:

.. code-block:: PowerShell

   cd <ProjectRoot>
   mkdir lib | cd
   git submodule add "https://github.com/VLSI-EDA/PoC.git" PoC
   cd PoC
   git remote rename origin github
   cd ..\..
   git add .gitmodules lib\PoC
   git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."

Command line instructions to clone the PoC-Library onto a Windows machine with
SSH protocol:

.. code-block:: PowerShell

   cd <ProjectRoot>
   mkdir lib | cd
   git submodule add "ssh://git@github.com:VLSI-EDA/PoC.git" PoC
   cd PoC
   git remote rename origin github
   cd ..\..
   git add .gitmodules lib\PoC
   git commit -m "Added new git submodule PoC in 'lib\PoC' (PoC-Library)."

