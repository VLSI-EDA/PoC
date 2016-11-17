compile-osvvm.ps1
-----------------

.. program:: compile-osvvm.ps1

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
