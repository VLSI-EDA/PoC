compile-xilinx-ise.ps1
----------------------

.. program:: compile-xilinx-ise.ps1

This script pre-compiles the Xilinx primitives. Because Xilinx offers two tool
chains (ISE, Vivado), this script will generate all outputs into a
:file:`xilinx-ise` directory and a symlink to :file:`xilinx` will be created.
This eases the coexistence of pre-compiled primitives from ISE and Vivado. The
symlink can be changed by the user or via :option:`-ReLink`.

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

.. option:: -ReLink

   Change the 'xilinx' symlink to 'xilinx-ise'.


.. rubric:: Additional Options for GHDL

.. option:: -VHDL93

   For GHDL only: Set VHDL Standard to '93.

.. option:: -VHDL2008

   For GHDL only: Set VHDL Standard to '08.


.. rubric:: GHDL Notes

Not all primitives and macros are available as plain VHDL source code. Encrypted
SecureIP primitives and netlists cannot be pre-compiled by GHDL.


.. rubric:: QuestaSim Notes

The pre-compilation for QuestaSim uses a build in program from Xilinx.
