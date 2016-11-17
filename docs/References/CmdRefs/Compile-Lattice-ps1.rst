compile-lattice.ps1
-------------------

.. program:: compile-lattice.ps1

This script pre-compiles the Lattice primitives. This script will generate all
outputs into a :file:`lattice` directory.


.. rubric:: Supported Simulators

+----------+--------------------------------------------+
| Target   | Description                                |
+==========+============================================+
| All      | pre-compile for all simulators             |
+----------+--------------------------------------------+
| GHDL     | pre-compile for the GHDL simulator         |
+----------+--------------------------------------------+
| Questa   | pre-compile for Metor Graphics QuestaSim   |
+----------+--------------------------------------------+


.. rubric:: Command Line Options

.. option:: -Help

   Show the embedded help page(s).

.. option:: -Clean

   Clean up directory before analyzing.

.. option:: -All

   Pre-compile all libraries and packages for all simulators.

.. option:: -GHDL

   Pre-compile the Altera Quartus libraries for GHDL.

.. option:: -Questa

   Pre-compile the Altera Quartus libraries for QuestaSim.


.. rubric:: Additional Options for GHDL

.. option:: -VHDL93

   For GHDL only: Set VHDL Standard to '93.

.. option:: -VHDL2008

   For GHDL only: Set VHDL Standard to '08.


.. rubric:: GHDL Notes

Not all primitives and macros are available as plain VHDL source code. Encrypted
primitives and netlists cannot be pre-compiled by GHDL.


.. rubric:: QuestaSim Notes

The pre-compilation for QuestaSim uses a build in program from Lattice.
