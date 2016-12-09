.. _CmdRef:Wrapper:

PoC Wrapper Scripts
###################

The PoC main program :program:`PoC.py` requires a prepared environment, which
needs to be setup by platform specific wrapper scripts written as shell
scripts language (PowerShell/Bash). Moreover, the main program requires a
supported Python version, so the wrapper script will search the best matching
language environment.

The wrapper script offers the ability to hook in user-defined scripts to prepared
(before) and clean up the environment (after) a PoC execution. E.g. it's possible
to load the environment variable :envvar:`LM_LICENSE_FILE` for the FlexLM license
manager.


.. rubric:: Created Environment Variables

.. envvar:: PoCRootDirectory

   The path to PoC's root directory.

---------------------------------

poc.ps1
========

.. program:: poc.ps1

:file:`PoC.ps1` is the wrapper for the Windows platform using a PowerShell script.
It can be debugged by adding the command line switch :option:`-D`. All parameters
are passed to :file:`PoC.py`.

.. option:: -D

   Enabled debug mode in the wrapper script.

.. describe:: Other arguments

   All remaining arguments are passed to :file:`PoC.py`.


poc.sh
======

.. program:: poc.sh

:file:`PoC.sh` is the wrapper for Linux and Unix platforms using a Bash script.
It can be debugged by adding the command line switch :option:`-D`. All parameters
are passed to :file:`PoC.py`.

.. option:: -D

   Enabled debug mode in the wrapper script.

.. describe:: Other arguments

   All remaining arguments are passed to :file:`PoC.py`.
