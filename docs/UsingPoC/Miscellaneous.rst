
Miscellaneous
#############

The directory ``PoCRoot\tools\`` contains several tools and addons to ease the
work with the PoC-Library and VHDL.


GNU Emacs
*********

.. TODO:: No documentation available.


Git
***

* ``git-alias.setup.ps1``/``git-alias.setup.sh`` registers new global aliasses in Git

  * ``git tree`` - Prints the colored commit tree into the console
  * ``git treea`` - Prints the colored commit tree into the console

  .. code-block:: Bash

     git config --global alias.tree 'log --decorate --pretty=oneline --abbrev-commit --date-order --graph'
     git config --global alias.tree 'log --decorate --pretty=oneline --abbrev-commit --date-order --graph --all'

Browse the `Git directory <https://github.com/VLSI-EDA/PoC/tree/master/tools/git>`_.


Notepad++
*********

The PoC-Library is shipped with syntax highlighting rules for `Notepad++ <https://notepad-plus-plus.org/>`_.
The following additional file types are supported:

* PoC Configuration Files (*.ini)
* PoC *.Files Files (*.files)
* PoC *.Rules Files (*.rules)
* Xilinx User Constraint Files (*.ucf): ``Syntax Highlighting - Xilinx UCF``

Browse the `Notepad++ directory <https://github.com/VLSI-EDA/PoC/tree/master/tools/Notepad%2B%2B>`_.


