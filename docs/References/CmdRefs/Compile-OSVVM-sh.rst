compile-osvvm.sh
----------------

.. program:: compile-osvvm.sh

This script pre-compiles the OSVVM packages. This script will generate all
outputs into a :file:`osvvm` directory.


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

.. option:: --help

   Show the embedded help page(s).

.. option:: --clean

   Clean up directory before analyzing.

.. option:: --all

   Pre-compile all libraries and packages for all simulators.

.. option:: --ghdl

   Pre-compile the Altera Quartus libraries for GHDL.

.. option:: --questa

   Pre-compile the Altera Quartus libraries for QuestaSim.


.. rubric:: Additional Options for GHDL

.. option:: --vhdl93

   For GHDL only: Set VHDL Standard to '93.

.. option:: --vhdl2008

   For GHDL only: Set VHDL Standard to '08.
