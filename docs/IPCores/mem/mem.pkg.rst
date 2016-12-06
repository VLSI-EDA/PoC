.. only:: html

   .. |gh-src| image:: /_static/logos/GitHub-Mark-32px.png
               :scale: 40
               :target: https://github.com/VLSI-EDA/PoC/blob/master/src/mem/mem.pkg.vhdl
               :alt: Source Code on GitHub

   .. sidebar:: GitHub Links

      |gh-src| :pocsrc:`Sourcecode <mem/mem.pkg.vhdl>`

.. _PKG:mem:

PoC.mem Package
===============

This package holds all component declarations, types and functions of the
:ref:`PoC.mem <NS:mem>` namespace.

It provides the following enumerations:

* ``T_MEM_FILEFORMAT`` specifies whether a file is in Intel Hex, Lattice
  Mem, or Xilinx Mem format.

* ``T_MEM_CONTENT`` specifies whether data in text file is in binary, decimal
  or hexadecimal format.

It provides the following functions:

* ``mem_FileExtension`` returns the file extension of a given filename.
* ``mem_ReadMemoryFile`` reads initial memory content from a given file.

.. only:: latex

   Source file: :pocsrc:`mem.pkg.vhdl <mem/mem.pkg.vhdl>`
