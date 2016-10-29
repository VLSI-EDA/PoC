Wrapper Script Hook Files
#########################

The shell scripts ``poc.ps1`` and ``poc.sh`` can be customized though hook
files, which are executed before and after a PoC command is executed. The
wrapper scripts support 4 kinds of hook files:
 * VendorPreHookFile
 * ToolPreHookFile
 * VendorPostHookFile
 * ToolPostHookFile

The wrapper scans the arguments given to the front-end script and searches
for known commands. If one is found, the hook files are scheduled before and
after the execution of the wrapped executable. The hook files are sourced
into the current execution and need to be located in the ``./py/Wrapper/Hooks``
directory.

A common use case is the preparation of special vendor or tool chain
environments. For example many EDA tools are using FlexLM as a license manager,
which needs the environments variable ``LM_LICENSE_FILE`` to be set. A
``PreHookFile`` can be used to load/export such an environment variable.



Examples
********

**Mentor QuestaSim on Linux:**

The PoC infrastructure is called with this command line:

.. code-block:: Bash

   ./poc.sh -v vsim PoC.arith.prng

The ``vsim`` command is recognized and the following events are scheduled:

 1. ``source ./py/Wrapper/Hooks/Mentor.pre.sh``
 2. ``source ./py/Wrapper/Hooks/Mentor.QuestaSim.pre.sh``
 3. Execute ``./py/PoC.py -v vsim PoC.arith.prng``
 4. ``source ./py/Wrapper/Hooks/Mentor.QuestaSim.post.sh``
 5. ``source ./py/Wrapper/Hooks/Mentor.post.sh``

If a hook files doesn't exist, it's skipped.


**Mentor QuestaSim on Windows:**

The PoC infrastructure is called with this command line:

.. code-block:: PowerShell

   .\poc.ps1 -v vsim PoC.arith.prng

The ``vsim`` command is recognized and the following events are scheduled:

  1. ``. .\py\Wrapper\Hooks\Mentor.pre.ps1``
  2. ``. .\py\Wrapper\Hooks\Mentor.QuestaSim.pre.ps1``
  3. Execute ``.\py\PoC.py -v vsim PoC.arith.prng``
  4. ``. .\py\Wrapper\Hooks\Mentor.QuestaSim.post.ps1``
  5. ``. .\py\Wrapper\Hooks\Mentor.post.ps1``

If a hook files doesn't exist, it's skipped.

FlexLM
******

Many EDA tools require an environment variable called ``LM_LICENSE_FILE``.
If no other tool settings are required, a common ``FlexLM.sh`` can be
generated. This file is used as a symlink target for each tool specific
hook file.

**Content of the `FlexLM.sh` script:**

.. code-block:: Bash

   export LM_LICENSE_FILE=1234@flexlm.company.com


**Create symlinks:**

.. code-block:: Bash

   ln -s FlexLM.sh Altera.Quartus.pre.sh
   ln -s FlexLM.sh Mentor.QuestaSim.pre.sh
