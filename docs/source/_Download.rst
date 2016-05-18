Download
========

**The PoC-Library** can be downloaded as a `zip-file <https://github.com/VLSI-EDA/PoC/archive/master.zip>`_ (latest 'master' branch) or cloned with ``git clone``
from GitHub. GitHub offers HTTPS and SSH as transfer protocols. See the `Download] for more details.


For HTTPS protocol use the URL ``https://github.com/VLSI-EDA/PoC.git`` or command
line instruction::

    cd <GitRoot>
    git clone --recursive https://github.com/VLSI-EDA/PoC.git PoC

For SSH protocol use the URL ``ssh://git@github.com:VLSI-EDA/PoC.git`` or command
line instruction::

    cd <GitRoot>
    git clone --recursive ssh://git@github.com:VLSI-EDA/PoC.git PoC

**Note:** The option ``--recursive`` performs a recursive clone operation for all linked `git submodules]. An additional ``git submodule init`` and
``git submodule update`` call is not needed anymore. 

.. http://git-scm.com/book/en/v2/Git-Tools-Submodules

**Note:** The created folder ``<GitRoot>\PoC`` is used as ``<PoCRoot>`` in later instructions. 
