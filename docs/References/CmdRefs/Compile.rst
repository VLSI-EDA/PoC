.. _CmdRef:PreCompile:

Pre-compile Scripts
###################

The following scripts can be used to pre-compile vendor's primitives or third
party libraries. Pre-compile vendor primitives are required for vendor specific
simulations or if no generic IP core implementation is available. Third party
libraries are usually used as simulation helpers and thus needed by many
testbenches.

The pre-compiled packages and libraries are stored in the directory :file:`/temp/precompiled/`.
Per simulator, one :file:`<simulator>/` sub-directory is created. Each simulator
directory in turn contains library directories, which may be grouped by the
library vendor's name: :file:`[<vendor>/]<library>/`.

So for example: :ref:`THIRD:OSVVM` pre-compiled with GHDL is stored in
:file:`/temp/precompiled/ghdl/osvvm/`. Note OSVVM is a single library and thus
no vendor directory is used to group the generated files. GHDL will also create
VHDL language revision sub-directories like :file:`v93/` or :file:`v08/`.

Currently the provided scripts support 2 simulator targets and one combined
target:

+----------+--------------------------------------------+
| Target   | Description                                |
+==========+============================================+
| All      | pre-compile for all simulators             |
+----------+--------------------------------------------+
| GHDL     | pre-compile for the GHDL simulator         |
+----------+--------------------------------------------+
| Questa   | pre-compile for Metor Graphics QuestaSim   |
+----------+--------------------------------------------+

The GHDL simulator distinguishes various VHDL language revisions and thus can
pre-compile the source for these language revisions into separate output
directories. The command line switch ``-All``/``--all`` will build the libraries
for all major VHDL revisions (93, 2008).


.. rubric:: Pre-compile Altera Libraries

.. toctree::

   Compile-Altera-sh
   Compile-Altera-ps1


.. rubric:: Pre-compile Lattice Libraries

.. toctree::

   Compile-Lattice-sh
   Compile-Lattice-ps1


.. rubric:: Pre-compile OSVVM Libraries

.. toctree::

   Compile-OSVVM-sh
   Compile-OSVVM-ps1


.. rubric:: Pre-compile UVVM Libraries

.. toctree::

   Compile-UVVM-sh
   Compile-UVVM-ps1


.. rubric:: Pre-compile Xilinx ISE Libraries

.. toctree::

   Compile-Xilinx-ISE-sh
   Compile-Xilinx-ISE-ps1


.. rubric:: Pre-compile Xilinx Vivado Libraries

.. toctree::

   Compile-Xilinx-Vivado-sh
   Compile-Xilinx-Vivado-ps1
